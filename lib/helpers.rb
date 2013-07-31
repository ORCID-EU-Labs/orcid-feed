helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end

  def is_orcid?(string)
    string.strip =~ /\A[0-9]{4}\-[0-9]{4}\-[0-9]{4}\-[0-9]{3}[0-9X]\Z/
  end

  def get_csl(style)
    response = Faraday.get "https://raw.github.com/citation-style-language/styles/master/#{style}.csl"
    style = response.status == 200 ? response.body : "apa"
  end
end
