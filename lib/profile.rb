# -*- coding: utf-8 -*-

require_relative 'work'

class Profile

  attr_accessor :orcid, :created_at, :updated_at, :biography, :given_names, :family_name, :name, :credit_name, :other_names, :reversed_name, :works, :a

  def initialize(orcid)
    conn = Faraday.new(:url => 'http://pub.orcid.org') do |c|
      c.request :json
      c.response :json, :content_type => /\bjson$/
      c.adapter Faraday.default_adapter
    end

    response = conn.get do |r|
      r.url "#{orcid}/orcid-profile"
      r.headers['Accept'] = 'application/json'
    end

    return nil unless response.status == 200
    result = response.body['orcid-profile']

    @orcid = orcid
    @created_at = Time.at(result['orcid-history']['submission-date']['value']/1000).utc.to_datetime
    @updated_at =Time.at(result['orcid-history']['last-modified-date']['value']/1000).utc.to_datetime
    @biography = result['orcid-bio']['biography'] ? result['orcid-bio']['biography']['value'] : nil 
    @given_names = result['orcid-bio']['personal-details']["given-names"]["value"]
    @family_name = result['orcid-bio']['personal-details']["family-name"].nil? ? "" : result['orcid-bio']['personal-details']["family-name"]["value"]
    @credit_name = result['orcid-bio']['personal-details']['credit-name'] ? result['orcid-bio']['personal-details']['credit-name']['value'] : nil
    
    if result["orcid-activities"] and result["orcid-activities"]["orcid-works"]["orcid-work"]
      works = result["orcid-activities"]["orcid-works"]["orcid-work"].map { |work| Work.new(work, reversed_name) }.uniq
      works = works.join("\n")
    else
      works = ""
    end
    @works = Bibliography.parse(works)

    # Use full name in bibliography
    @works.extend_initials [given_names, family_name]
  end

  def name
    credit_name ? credit_name : [given_names, family_name].join(" ")
  end

  def reversed_name
    [family_name, given_names].join(", ")
  end
  
end