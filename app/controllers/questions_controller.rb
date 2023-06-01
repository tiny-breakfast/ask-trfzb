# frozen_string_literal: true

class QuestionsController < ApplicationController
    DEFAULT_QUESTION = 'What is "Pride and Prejudice" about?'
    def index
        render locals: {
            question: DEFAULT_QUESTION
        }
    end

    def create
        render json: {"yabba" => "dabba"}
    end
end
