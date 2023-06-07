require "rails_helper"
require 'webdrivers'


RSpec.describe "question form", type: :system do
    include Rails.application.routes.url_helpers

    before :all do
        default_url_options[:host] = "localhost"
    end

    it "visiting the index" do
        visit root_url
        
        expect(page).to have_content('Ask "the Real Frank Zappa Book"')
    end
end
