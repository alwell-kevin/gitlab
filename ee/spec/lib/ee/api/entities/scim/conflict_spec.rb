# frozen_string_literal: true

require 'spec_helper'

describe ::EE::API::Entities::Scim::Conflict do
  let(:params) { { detail: 'error' } }
  let(:entity) do
    described_class.new(params)
  end

  subject { entity.as_json }

  it 'contains the schemas' do
    expect(subject[:schemas]).not_to be_empty
  end

  it 'contains the detail' do
    expect(subject[:detail]).to eq(params[:detail])
  end

  it 'contains the status' do
    expect(subject[:status]).to eq(409)
  end
end
