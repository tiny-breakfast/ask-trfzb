require "rails_helper"

require "./app/services/answer"

RSpec.describe "POST /questions", type: :request do
    before do
        allow(Answer).
            to receive(:answer_question).
            with("What's totally bitchen in Encino?").
            and_return([
                "There's, like, the Galleria, and, like, all these, like, really great shoe stores.",
                "some kind of context",
            ])
    end

    it "creates a record" do
        expect { post "/questions", params: { question: "What's totally bitchen in Encino?" } }.
            to change { Question.count }

        question = Question.find_by(question: "What's totally bitchen in Encino?")
        expect(question.question).to eq("What's totally bitchen in Encino?")
        expect(question.answer).to eq("There's, like, the Galleria, and, like, all these, like, really great shoe stores.")
        expect(question.context).to eq("some kind of context")
    end

    context "when the question has been asked before" do
        let!(:question) do
            Question.create!(
                question: "What's totally bitchen in Encino?",
                answer: "There's, like, the Galleria, and, like, all these, like, really great shoe stores.",
                context: "some kind of context",
            )
        end

        it "does not create a record" do
            expect { post "/questions", params: { question: "What's totally bitchen in Encino?" } }.
                to_not change { Question.count }

            question = Question.find_by(question: "What's totally bitchen in Encino?")
            expect(question.ask_count).to eq(2)
        end
    end

    it "responds with the answer" do
        post "/questions", params: { question: "What's totally bitchen in Encino?" }
        response_body = JSON.parse(response.body)

        expect(response_body["question"]).to eq "What's totally bitchen in Encino?"
        expect(response_body["answer"]).to eq "There's, like, the Galleria, and, like, all these, like, really great shoe stores."
    end
end
