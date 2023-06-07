require "rails_helper"
require 'webdrivers'

RSpec.describe "question form", type: :system do
    include Rails.application.routes.url_helpers

    before :all do
        default_url_options[:host] = "localhost"
    end

    before do
        allow(Answer).
            to receive(:answer_question).
            with("What's totally bitchen in Encino?").
            and_return([
                "There's, like, the Galleria, and, like, all these, like, really great shoe stores.",
                "some kind of context",
            ])
    end

    describe "visiting the index" do
        it "shows the form and then shows the answer" do
            visit root_url

            expect(page).to have_content('Ask "the Real Frank Zappa Book"')
            within("#question-form") do
                fill_in 'Ask a question', with: "What's totally bitchen in Encino?"
            end

            click_button('Ask question')
            sleep(30.seconds)

            expect(page).to have_content("There's, like, the Galleria, and, like, all these, like, really great shoe stores.")
            expect(page).to have_content("Ask another question")
        end
    end

    describe "viewing a particular question and answer" do
        let!(:question) do
            Question.create!(
                :question => "some question",
                :answer => "some answer",
            )
        end

        it "shows the form and then shows the answer" do
            visit question_url(:id => question.id)

            expect(page).to have_content('Ask "the Real Frank Zappa Book"')
            expect(page).to_not have_content("Ask question")
            within("#question-form") do
                expect(page).to have_content("some question")
            end

            expect(page).to have_content("some answer")
        end
    end
end
