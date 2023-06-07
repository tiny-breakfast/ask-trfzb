# frozen_string_literal: true

class QuestionsController < ApplicationController
    DEFAULT_QUESTION = 'What is "the Real Frank Zappa Book" about?'

    def index
        render locals: {
            question: DEFAULT_QUESTION,
            answer: nil,
            id: nil,
        }
    end

    def create
        question = params[:question].strip
        question += '?' unless question.ends_with?('?')

        previously_asked_question = Question.where(question: question).limit(1).first

        if previously_asked_question
            previously_asked_question.ask_count += 1
            previously_asked_question.save!
            render json: { question: previously_asked_question.question, answer: previously_asked_question.answer, id: previously_asked_question.id }
            return
        end

        answer, context = Answer.answer_question(question)

        question_record = Question.create!(question: question, answer: answer, context: context)

        render json: { question: question, answer: answer, id: question_record.id }
    end

    def show
        question_id = params[:id]

        begin
            question = Question.find(question_id)
        rescue ActiveRecord::RecordNotFound
            redirect_to root_url
            return
        end

        render action: 'index', locals: {
            question: question.question,
            answer: question.answer,
            id: question.id
        }
    end
end
