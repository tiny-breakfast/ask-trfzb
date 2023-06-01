require 'csv'
require 'openai'
require 'matrix'

module Answer
    BOOK = './static/pandp12p.pdf'
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
    HEADER = "Pride and Prejudice is an 1813 novel of manners by Jane Austen. It is set in the early 19th century in southern England. The novel follows the character development of Elizabeth (Lizzie) Bennet, the protagonist of the book, who learns about the repercussions of hasty judgments and comes to appreciate the difference between superficial goodness and actual goodness. These are questions and answers about the book. Please keep your answers to three sentences maximum, and speak in complete sentences. Stop speaking once your point is made.\n\nContext that may be useful:\n"

    # wholly taken from https://www.sparknotes.com/lit/pride/key-questions-and-answers/
    QUESTIONS_AND_ANSWERS = {
        "Why does Charlotte Lucas marry Mr. Collins?" => "Charlotte marries Mr. Collins because he has a stable income and offers her the opportunity to have a home of her own. She does not love him, but she doesn’t believe that love is essential for a successful marriage. As Charlotte explains to Elizabeth, “I’m not a romantic, you know. I never was. I ask only a comfortable home.” Since Charlotte is not particularly beautiful and is growing older, she decides to make the most of an opportunity.",
        "Why is Lizzy Mr. Bennet’s favorite daughter?" => "Lizzy is her father’s favorite child because she is the only one to share his wit and sense of humor. Early in the novel, Mr. Bennet is described as “a mixture of quick parts, sarcastic humor, caprice, and reserve.” Lizzy shares many of these qualities: she is also a keen observer of human nature, and she also possesses a dry and witty sense of humor. Mr. Bennet admires that Lizzy can think for herself and make good decisions, which is why he supports her decision to refuse Mr. Collins’s proposal.",
        "Why does Darcy dislike Wickham?" => "Darcy has long seen Wickham to be selfish and unscrupulous, characterized by “vicious propensities.” In particular, Darcy detests Wickham because after Darcy refused to give Wickham money, Wickham seduced Darcy’s fifteen-year-old sister and planned to elope with her in order to get his hands on her fortune. Although Darcy has never made this story public in order to protect his sister’s reputation, he knows that Wickham has a history of predatory behavior.",
        "Why does Lizzy form a negative first impression of Darcy?" => "When Lizzy first meets Darcy at the ball, he makes a bad first impression by being cold, reserved, and unfriendly toward everyone. Like the other guests, Lizzy decides that “he was the proudest, most disagreeable man in the world.” The bad impression is further solidified when she accidentally overhears him talking about her and commenting on her appearance. Darcy remarks that she is “tolerable but not handsome enough to tempt me.”",
        "Why does Lizzy reject Darcy’s first proposal to her?" => "Lizzy rejects Darcy’s first proposal because while he admits to loving her, he also says many insulting things about her family and social position. Darcy makes clear “his sense of her inferiority, of its being a degradation, of the family obstacle, which judgment had always opposed to inclination.” He also seems confident that she will consider it an honor to marry him. These attitudes are offensive to Lizzy, because she does not think Darcy is inherently better than her.",
        "What is the significance of the novel’s opening line?" => "The novel’s opening line summarizes the story that follows by focusing the reader’s attention on the subject of marriage and the two main characters to come: “the single man in possession of a good fortune”—Mr. Darcy—and his wife-to-be—Elizabeth Bennet. The sentence also suggests the novel’s import and timelessness by suggesting that its plot and themes are “truths universally acknowledged.” The line’s tone is lighthearted, which sets the mood for the bulk of the narrative.",
        "According to Mr. Darcy, what qualities make a woman “accomplished”?" => "Mr. Darcy agrees with Charles Bingley that an accomplished woman must have a knowledge of music, art, and languages and that she should also possess a “certain something in her air and manner of walking, the tone of her voice.” However, Darcy adds one more quality to the list: “the improvement of her mind by extensive reading.” This addition, of course, applies explicitly to Elizabeth. The reader will learn that Mr. Darcy’s family estate at Pemberley has an extensive library and that Mr. Darcy’s and Elizabeth’s articulate and literate banter will constitute much of their mutual attraction.",
        "What role do letters play in the novel?" => "In addition to face-to-face conversation, letters are the means that characters use to convey their intentions and wishes and one of the ways readers learn important information about characters and critical plot developments. A few examples of the role letters play include the following: Elizabeth writes to her mother to summon a carriage to Netherfield; Mr. Collins sends a letter to Mr. Bennet announcing his upcoming visit; Mr. Darcy sends a long letter of explanation to Elizabeth, which marks the beginning of her change of heart toward him; Mr. Gardiner communicates with his brother-in-law about Lydia by letter; Mr. Gardiner sends a letter to Elizabeth in which he confirms Mr. Darcy’s generosity to her family; Lydia sends letters to her family before her marriage, assuring them of her health and happiness; and Mr. Bennet’s brief letter to Mr. Collins announcing Elizabeth’s marriage to Mr. Darcy slyly suggests that Mr. Bennet will have to console Lady Catherine.",
        "What is revealed about the characters after Elizabeth rejects Mr. Collins’s proposal?" => "After Elizabeth rejects Mr. Collins’s proposal, readers discover different characters’ opinions about marriage. Readers learn that Elizabeth will not marry someone with whom she isn’t in love and that she considers Mr. Collins an imbecile. Readers learn that Mr. Collins is intent on finding a wife and that he does not care who she is, for he proposes the next day to Charlotte Lucas, who accepts. Mr. Bennet respects Elizabeth’s judgments and doesn’t want to see her marry unhappily. Mrs. Bennet thinks Elizabeth has made a terrible mistake because Mrs. Bennet cares most about seeing her five daughters married well.",
        "How is the novel a critique of the social norms of its time?" => "Austen shows that people who have more money or a higher social status are not necessarily better people. In fact, often they have less integrity, less intelligence, and less ability to make the world a better place. For example, Caroline Bingley finds the Bennet sisters boring and their mother intolerable, but she is only trying to woo Mr. Darcy for herself. Mr. Collins is a buffoon who defines himself by his patron and prattles on about topics that do not interest his audience. Lady Catherine, a character of high social standing, is conceited and rude to Elizabeth in their final conversation. Austen uses her characters to reveal a universal truth: Wealth and status do not make people good people.",
        "How are Mr. and Mrs. Bennet different?" => "The nervous Mrs. Bennet only wants her daughters to marry for fortune and status, and soon, but the logical Mr. Bennet enjoys the company of his daughters and hopes that they marry for love when they are ready. Mrs. Bennet’s domain is the hearth and the kitchen, and she is flighty and busy most of the time. Mr. Bennet’s domain is his study, and he prefers to withdraw and detach from the family. Elizabeth is Mr. Bennet’s favorite because of her intelligence, but Mrs. Bennet doesn’t seem to play favorites. Her ambitions for her daughters are equal and consistent: She wants them all to marry upward.",
        "What is entailment, and what role does it play in the novel?" => "Based on the evidence in the novel, entailment is a legal situation in which a property or estate automatically transfers to a predetermined heir regardless of how many children the property owner has. In the case of the Bennet family, their property will automatically be inherited by William Collins, not any of the Bennet daughters. This controversial reality is evoked many times by Mrs. Bennet and confirmed by her husband and children, and the situation provides the momentum for marrying off the five Bennet daughters to men of means since the family property can never become theirs. Mrs. Bennet reveals her feelings about entailment to Mr. Bennet when she says, “I never can be thankful, Mr. Bennet, for any thing about the entail. How any one could have the conscience to entail away an estate from one’s own daughters I cannot understand; and all for the sake of Mr. Collins too!—Why should he have it more than anybody else?”",
        "Who is Lady Catherine de Bourgh, and how does she influence the plot?" => "Lady Catherine de Bourgh is Mr. Darcy’s aunt and the benefactor to Mr. Collins and his wife, Charlotte, which makes her an important supporting character. She represents the old way of planned marriage and clerical servitude. Lady Catherine says that her daughter must marry Mr. Darcy since it was planned upon her daughter’s birth. Lady Catherine is powerful and tries to forbid Elizabeth and Mr. Darcy’s marriage, but Elizabeth undoes her power. The old way does not prevail—love does.",
        "Why does Wickham lie to Elizabeth?" => "George Wickham lies to Elizabeth and omits many of the details about the truth because he wants to impress her and disparage Mr. Darcy. Wickham tells Elizabeth that Mr. Darcy’s father’s wishes were ignored when they were not. He fails to tell her about his dalliance with Georgiana Darcy, his leaving his studies in both theology and law, and his mismanagement of money. It’s ironic that Elizabeth declares that Mr. Darcy should be publicly disgraced when her comment and attitude apply more to Wickham than to Mr. Darcy.",
        "What role does prejudice play in the novel?" => "Repeatedly, the novel warns against trusting one’s first impressions or prejudices. Elizabeth’s first impression of Mr. Darcy is that he is arrogant and aloof, but in the end, she loves him deeply. Conversely, her first impression of Wickham is that he is charming and good-looking, but he turns out to be a liar and a cheat. The Bennets’ first impression of Lady Catherine is admiration for her great wealth and status, but they eventually despise her and her outdated attitudes. Over the course of the novel, several characters revise their prejudices as loathing turns to admiration and vice versa.",
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

            prompt = HEADER +
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
