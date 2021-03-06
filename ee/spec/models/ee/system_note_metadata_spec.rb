# frozen_string_literal: true

require 'spec_helper'

describe EE::SystemNoteMetadata do
  %i[
    designs_added designs_modified designs_removed
    vulnerability_confirmed vulnerability_dismissed vulnerability_resolved
  ].each do |action|
    context 'when action type is valid' do
      subject do
        build(:system_note_metadata, note: build(:note), action: action )
      end

      it { is_expected.to be_valid }
    end
  end
end
