require 'csv'
require 'openai'
require 'matrix'

module Answer
    BOOK = './static/the-real-frank-zappa-book.pdf'
    PAGES_CSV = CSV.read("#{BOOK}.pages.csv").drop(1).each do |row|
        tokens = row[2]
        row[2] = Integer(tokens)
    end
    # key is "Page X", value is an 4096 element array of floats
    EMBEDDINGS =
        begin
            # 14M raw on disk.
            CSV.read("#{BOOK}.embeddings.csv").drop(1).reduce({}) do |embeddings, row|
                title = row[0]
                embeddings[title] = row.drop(1).map(&method(:Float))
                embeddings
            end
        end

    OPEN_AI_CLIENT = OpenAI::Client.new(access_token: ENV['OPEN_AI_ACCESS_TOKEN'])
    QUESTION_EMBEDDINGS_MODEL = "text-search-curie-query-001"
    COMPLETIONS_MODEL = "text-davinci-003"
    COMPLETIONS_API_PARAMS = {
        # "We use temperature of 0.0 because it gives the most predictable, factual answer."
        temperature: 0.0,
        max_tokens: 150, # magic number from source
        model: COMPLETIONS_MODEL,
    }.freeze

    MAX_SECTION_LEN = 500
    SEPARATOR = "\n* "
    SEPARATOR_LEN = 3

    # cribbed from https://en.wikipedia.org/wiki/Frank_Zappa
    BOOK_SUMMARY = "Frank Zappa was an American musician, composer, and bandleader. His work is characterized by nonconformity, free-form improvisation, sound experimentation, musical virtuosity and satire of American culture.\n"
    # cribbed from askmybook
    COACHING = "These are questions and answers by him. Please keep your answers to three sentences maximum, and speak in complete sentences. Stop speaking once your point is made.\n\nContext that may be useful:\n"

    # cobbled together from the book itself, and from interview Q&As
    QUESTIONS_AND_ANSWERS = {
        "What was your biggest problem with school?" => "My biggest problem, throughout school, was that the things they were trying to teach me tended not to be the kinds of things I was interested in. I grew up with poison gas and explosives -- with the children of people who built these things for a living. Did I give a fuck about algebra?",

        "Did you read Shakespeare?" => "The epigraphs at the heads of chapters were researched and inserted by Peter -- I mention this because I wouldn't want anybody to think I sat around reading Flaubert, Twitchell and Shakespeare all day.",

        "Why did you write an autobiography?" => "One of the reasons for doing this is the proliferation of stupid books (in several languages) which purport to be About Me. I thought there ought to be at least ONE, somewhere, that had real stuff in it. The opportunity to say stuff in print about tangential subjects is appealing.",

        "How did teenaged Frank Zappa treat visitors to his house?" => "All through high school, whenever people came over, I would force them to listen to Varèse -- because I thought it was the ultimate test of their intelligence.",

        "Should I quit school or go on?" => "I always tell them you should infiltrate. Hurry up and take over your father's job and do it right. It's fortunate that something like Psychedelia and Haight-Ashbury and all the rest of that goes on because it takes the focus off of the possibility that somebody who looks clean, straight, wholesome, right-wing and harmless is going to come in there and just do it while they're not looking. It's a much more frightening concept thinking it's some hairy creep that's going to take over your job. It's not going to be that way, it's going to be some guy who is straight.",

        "Is music better or worse than when you started? And I don’t mean your music I mean music in general." => "Well if you’re talking about the known musical universe - in other words, what you can hear on the radio and what they show you on MTV - it is way worse. But that doesn’t mean that there aren’t good things out there that we don’t know about. It’s just that the broadcasters are not letting us find out about it. Because it’s hard for me to believe that all the sudden with the advent of MTV all good songs ceased to be written, all good bands ceased to be formed. I just don’t think that nature works that way. In some place there’s good musicians and good composers and good tunes all over this country and other countries, we just don’t know about them because the people who determine what you get to see and hear have no taste.",

        "Do you enjoy touring?" => "If I had to choose I'd be touring. I like to have something happening where the music is alive, and there's people in it, and some feeling to it. It's so hard to get something that exciting in a studio. I think that anyone that wants to shut himself up in a studio for the rest of his life is missing out. To me, the studio is a useful tool. It's a great place to do certain experimental things. There are a number of things that are feasible in the studio that are impossible on a stage, like overdubbing. But for getting out and 'doing it' you've got to go on the road.",

        "Are you a rebel without a cause?" => "Hardly, because my cause is music. I'm interested in ﬁnding out what can be done with different types of musical forms of expression – without any interference. It's very difﬁcult to do in the United States because, unless you can sell it to somebody, you can't keep doing it.,",

        "What is the concept of 'the Big Note'?" => "The concept of the Big Note is that everything in the universe is composed basically of vibrations – light is a vibration, sound is a vibration, atoms are composed of vibrations – and all these vibrations just might be harmonics of some incomprehensible fundamental cosmic tone.",

        "Would you say that music is your whole life?" => "Yes, just about.",
    }

    class << self
        def answer_question(question, **options)
            pages_csv = options[:pages_csv] || PAGES_CSV
            embeddings = options[:embeddings] || EMBEDDINGS

            most_relevant_document_sections = order_document_sections_by_query_similarity(question, embeddings)

            prompt, context = construct_prompt(
                question,
                pages_csv,
                most_relevant_document_sections,
            )

            response = OPEN_AI_CLIENT.completions(
                parameters:  {
                    prompt: prompt,
                    **COMPLETIONS_API_PARAMS,
                }
            )

            return [
                response["choices"][0]["text"].strip,
                context,
            ]
        end

        def construct_prompt(question, pages_csv, most_relevant_document_sections)
            chosen_sections = []
            chosen_sections_len = 0

            most_relevant_document_sections.each do |(_, section_index)|
                document_section = pages_csv.select { |row| title = row[0]; title == section_index }.first
                content = document_section[1]
                tokens = document_section[2]

                chosen_sections_len += (tokens + SEPARATOR_LEN)

                if chosen_sections_len > MAX_SECTION_LEN
                    space_left = MAX_SECTION_LEN - chosen_sections_len - SEPARATOR.length
                    chosen_sections << (SEPARATOR + content[0...space_left])
                    break
                end

                chosen_sections << (SEPARATOR + content)
            end

            context = chosen_sections.join("")

            prompt = BOOK_SUMMARY +
                COACHING +
                context +
                QUESTIONS_AND_ANSWERS.take(10).map { |q, a| "\n\n\nQ: #{q}\n\nA: #{a}" }.join("") +
                "\n\n\nQ: #{question}\n\nA: "
            
            return [
                prompt,
                context,
            ]
        end

        # Find the query embedding for the supplied query, and compare it against all of the pre-calculated document embeddings
        # to find the most relevant sections.
        # 
        # Return the list of document sections, sorted by relevance in descending order.
        def order_document_sections_by_query_similarity(question, embeddings) # -> list[(float, (str, str))]:
            question_embedding = get_question_embedding(question)

            return embeddings.map do |doc_index, doc_embedding|
                vector_similarity = Vector[*question_embedding].dot(Vector[*doc_embedding])
                [
                    vector_similarity,
                    doc_index,
                ]
            end.sort.reverse
        end

        def get_question_embedding(text)
            result = OPEN_AI_CLIENT.embeddings(
                parameters: {
                    model: QUESTION_EMBEDDINGS_MODEL,
                    input: text,
                },
            )

            return result["data"][0]["embedding"]
        end
    end
end
