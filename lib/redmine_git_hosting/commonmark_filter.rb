# frozen_string_literal: true

require 'html/pipeline/filter'
require 'html/pipeline/text_filter'
require 'commonmarker'
require 'rouge'

module RedmineGitHosting
  class CommonmarkFilter < HTML::Pipeline::TextFilter
    def initialize(text, context = nil, result = nil)
      super text, context, result
      @text = @text.delete "\r"
    end

    # Convert Markdown to HTML using Commonmarker
    def call
      html = CommonMarker.render_html(@text, :DEFAULT, [:table, :autolink, :strikethrough])
      html.rstrip!
      html
    end
  end
end
