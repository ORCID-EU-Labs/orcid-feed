helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end

  def is_orcid?(string)
    string.strip =~ /\A[0-9]{4}\-[0-9]{4}\-[0-9]{4}\-[0-9]{3}[0-9X]\Z/
  end

  def get_csl(style)
    return "apa" if ["apa", "", nil].include? style

    response = Faraday.get "http://www.zotero.org/styles/#{style}"
    return "apa" unless response.status == 200

    parent  = Nokogiri::XML(response.body).at_css('link[rel="independent-parent"]')
    return response.body unless parent

    style = File.basename(parent["href"])
    get_csl(style)
  end
end
