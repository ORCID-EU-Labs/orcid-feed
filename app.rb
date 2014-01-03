# -*- coding: utf-8 -*-

require "rack/cache"
require 'sinatra'
require 'sinatra/config_file'
require 'sinatra/respond_to'
require "sinatra/reloader" if development?
require 'faraday'
require 'faraday_middleware'
require 'builder'
require 'rdiscount'
require 'bibtex'
require 'rdf'
require 'citeproc'
require 'multi_json'
require 'uri'
require 'json'

Sinatra::Application.register Sinatra::RespondTo
use Rack::Cache

require_relative 'lib/helpers'
require_relative 'lib/profile'
require_relative 'lib/bibliography'
require_relative 'lib/work'

# Configure logging
require 'log4r'
include Log4r
logger = Log4r::Logger.new('test')
logger.trace = true
logger.level = DEBUG
formatter = Log4r::PatternFormatter.new(:pattern => "[%l] %t  %M")
Log4r::Logger['test'].outputters << Log4r::Outputter.stdout
Log4r::Logger['test'].outputters << Log4r::FileOutputter.new('logtest', 
                                              :filename =>  'log/app.log',
                                              :formatter => formatter)
logger.info 'got log4r set up'
#use Rack::Logger, logger

configure do
  config_file 'config/settings.yml'

  #set :environment, :development
  set :markdown, :layout_engine => :erb, :layout => :layout

  mime_type :bib, 'application/x-bibtex'
  mime_type :txt, 'text/x-bibliography'
  mime_type :yml, 'application/x-yaml'

  file = File.new("#{settings.root}/log/#{settings.environment}.log", 'a+')
  file.sync = true
  use Rack::CommonLogger, file
end

configure :development do
  enable :raise_errors, :dump_errors
end

before do
  cache_control :public, :must_revalidate, :max_age => 60
end

get '/' do
  markdown :index
end

get '/:orcid' do
  unless is_orcid?(params[:orcid]) && @profile = Profile.new(params[:orcid])
    error 404
  end

  respond_to do |format|
    format.html do
      citations = ""
      # ToDo: optimize, create processor & fetch CSL style beforehand, instead of repeating for each work
      style = get_csl(params[:style])
      @profile.works.map do |work|
        
        # if doi = work.doi
        #   # Fetch authoritative metadata from central DOI resolver

        #  # Figure out from which RA (registration authority) this DOI comes
        #   prefix = doi =~ /(\d+\.\d+)
        #   Faraday.get "http://dev.datacite.org/doi-ra/prefix/" + doi_prefix


        #   # TODO! need caching here, probably store previous lookups in MongoDb 

        # end

        # TODO if user asks for it, use basic heuristics to use some useful URL (ideally DOI one, otherwise
        # the work.url attribute) to hyperlink the work title.
        citation = CiteProc.process(work.to_citeproc, :format => 'html', :style => style)
        if work.respond_to? :doi or work.respond_to? :url
          url = "" 
          if work.respond_to? :doi 
            url = 'http://dx.doi.org/' + work.doi 
          else
            url = work.url
          end
          citation.gsub! work.title, '<a href="' + url + '">' + work.title + '</a>'
        end
        citations += '<div class="csl-entry '+ work.type.to_s + '">' + citation + "  </div>\n"
     end
      # Some post-processing to hyperlink DOIs and URLs
      citations.gsub! /[^"](http:\S+)/, '<a href="\1">\1</a>'
      citations.gsub! /doi:(10\.\d+\/\S+)/i, '<a href="http://dx.doi.org/\1">doi:\1</a>'
      

      # Finally return bibliography to caller, with JSONP wrapper if required
      citations = '<div class="hangindent csl-bib-body">' + citations + '</div>'
      if callback = params[:callback]
        citations = callback + '({"html" : ' + JSON.generate(citations, quirks_mode: true) + '})'
      end
      return citations
    end
    format.rss { builder :show }
    format.bib { @profile.to_bib }
    format.xml { @profile.to_xml }
    format.json { @profile.to_json }
    format.yml { @profile.to_yaml }
    format.txt { @profile.works.map { |work| CiteProc.process(work.to_citeproc, :style => get_csl(params[:style])) }.join("\n") }
  end
end

not_found do
  erb "The requested ORCID was not found."
end
