require 'openai'

module OpenAI
    # fixme
    PAGES_CSV = CSV.new
    EMBEDDINGS_CSV = CSV.new

    OPEN_AI_CLIENT = OpenAI::Client.new(access_token: ENV['OPEN_AI_ACCESS_TOKEN'])
    COMPLETIONS_MODEL = "text-davinci-003"
    COMPLETIONS_API_PARAMS = {
        # We use temperature of 0.0 because it gives the most predictable, factual answer.
        temperature: 0.0,
        max_tokens: 150, # magic number from source
        model: COMPLETIONS_MODEL,
    }.freeze

    class << self
        def answer_question(question, **options)
            pages_csv = options[:pages_csv] || PAGES_CSV
            embeddings_csv = options[:embeddings_csv] || EMBEDDINGS_CSV

            prompt, context = construct_prompt(
                question,
                pages_csv,
                embeddings_csv,
            )

            response = OPEN_AI_CLIENT.completion(
                parameters:  {
                    prompt: prompt,
                    **COMPLETIONS_API_PARAMS,
                }
            )

            return [
                response["choices"][0]["text"].strip(" \n"),
                context,
            ]
        end

        def construct_prompt()
    end
end
