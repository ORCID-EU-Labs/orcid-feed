require 'spec_helper'

describe "App" do

  context "home page" do
    it "should respond to get" do
      get '/'
      last_response.should be_ok
      last_response.body.should match(/Introduction/)
    end
  end

  context "content negotiation" do
    let(:orcid) { "0000-0002-1825-0097" }

    it "should understand HTML" do
      get "/#{orcid}"
      last_response.should be_redirect_to('/login')
    end

    it "should understand RSS" do
      #last_request.env["HTTP_ACCEPT"] = 'application/json'
      # stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      #   stub.get('/0000-0002-1825-0097') { [200, {}, File.read(fixture_path + 'response.json')] }
      # end
      get "/#{orcid}", nil, { 'HTTP_ACCEPT' => "application/x-bibtex" }

      last_response.should eq(2)
      last_response.body.should match(/Introduction/)
    end
  end

  context "errors" do
    let(:orcid) { "0000-0002-1825-009" }
    it "wrong ORCID" do
      get "/#{orcid}"
      last_response.status.should eq(404)
      last_response.body.should match(/The requested ORCID was not found/)
    end
  end
end
