# frozen_string_literal: true

module EE
  module PreviewMarkdownService
    def quick_action_types
      super.push('Epic')
    end
  end
end
