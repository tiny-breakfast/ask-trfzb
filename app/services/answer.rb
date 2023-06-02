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

    # partially cribbed from Wikipedia, partially from Sahil's header

    # well shit. If I wanna change the book, then I have to re-do the
    # header and questions and answers.

    BOOK_SUMMARY = "The Real Frank Zappa Book is Frank Zappa's autobiography. Frank Zappa takes us on a wild, funny trip through his life and times. Along the way, Zappa offers his inimitable views on many things such as art, politics and beer.\n"
    COACHING = "These are questions and answers about the book. Please keep your answers to three sentences maximum, and speak in complete sentences. Stop speaking once your point is made.\n\nContext that may be useful:\n"

    # wholly taken from https://www.sparknotes.com/lit/pride/key-questions-and-answers/
    QUESTIONS_AND_ANSWERS = {
        "What was Frank Zappa's biggest problem with school?" => "My biggest problem, throughout school, was that the things they were trying to teach me tended not to be the kinds of things I was interested in. I grew up with poison gas and explosives -- with the children of people who built these things for a living. Did I give a fuck about algebra?",
        "Did Frank Zappa read Shakespeare?" => "The epigraphs at the heads of chapters were researched and inserted by Peter -- I mention this because I wouldn't want anybody to think I sat around reading Flaubert, Twitchell and Shakespeare all day.",
        "Why did Frank Zappa write this book?" => "One of the reasons for doing this is the proliferation of stupid books (in several languages) which purport to be About Me. I thought there ought to be at least ONE, somewhere, that had real stuff in it. The opportunity to say stuff in print about tangential subjects is appealing.",
        "How did teenaged Frank Zappa treat visitors to his house?" => "All through high school, whenever people came over, I would force them to listen to Varèse -- because I thought it was the ultimate test of their intelligence.",
        
    }

    class << self
        def answer_question(question, **options)
            pages_csv = options[:pages_csv] || PAGES_CSV
            embeddings = options[:embeddings] || EMBEDDINGS

            prompt, context = construct_prompt(
                question,
                pages_csv,
                embeddings,
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

        def construct_prompt(question, pages_csv, embeddings)
            most_relevant_document_sections = order_document_sections_by_query_similarity(question, embeddings)

            chosen_sections = []
            chosen_sections_len = 0
            # chosen_sections_indexes = []

            most_relevant_document_sections.each do |(_, section_index)|
                document_section = pages_csv.select { |row| title = row[0]; title == section_index }.first
                content = document_section[1]
                tokens = document_section[2]

                chosen_sections_len += (tokens + SEPARATOR_LEN)

                if chosen_sections_len > MAX_SECTION_LEN
                    space_left = MAX_SECTION_LEN - chosen_sections_len - SEPARATOR.length
                    chosen_sections << (SEPARATOR + content[0...space_left])
                    # chosen_sections_indexes << str(section_index)
                    break
                end

                chosen_sections << (SEPARATOR + content)
                # chosen_sections_indexes << section_index
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
