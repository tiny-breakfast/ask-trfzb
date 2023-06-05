require "openai"

RSpec.describe Answer do
    let(:open_ai_client) do
        instance_double(
            OpenAI::Client
            :embeddings => {}
            :completiosn => {
                'choices' => [
                    'text' => '"The Real Frank Zappa Book" is an autobiography that covers my life from childhood to the present day. It includes stories about my family, my musical career, my views on politics and culture, and my thoughts on the music industry. It also includes a selection of epigraphs from various authors, as well as a few of my own drawings.',
                ]
            }
        )
    end

    it "" do
        answer, context = Answer.answer_question('What is "the Real Frank Zappa Book" about?', client: open_ai_client)

        expect(answer).to eq()

    end
end
