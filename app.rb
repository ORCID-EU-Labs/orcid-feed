# -*- coding: utf-8 -*-

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

Sinatra::Application.register Sinatra::RespondTo

require_relative 'lib/helpers'
require_relative 'lib/profile'
require_relative 'lib/bibliography'
require_relative 'lib/work'

STYLES = Set[:apa, 
             :mla, 
             :vancouver, 
             :chicago_author_date]

configure do
  config_file 'config/settings.yml'

  #set :environment, :development

  mime_type :bib, 'application/x-bibtex'
  mime_type :txt, 'text/x-bibliography'

  file = File.new("#{settings.root}/log/#{settings.environment}.log", 'a+')
  file.sync = true
  use Rack::CommonLogger, file
end

configure :development do
  enable :raise_errors, :dump_errors
end

get '/' do
  markdown :index, :layout_engine => :erb
end

get '/:orcid' do
  redirect '/' unless is_orcid?(params[:orcid])

  @profile = Profile.new(params[:orcid])

  respond_to do |format|
    format.html do
      redirect "http://orcid.org/#{params[:orcid]}", 301
    end
    format.rss { builder :show }
    format.bib { @profile.works }
    format.json { @profile.works.to_citeproc.to_json }
    format.txt do
      default = lambda { :apa }
      style = STYLES.detect(default) { |s| s == params[:style].to_sym }
      @profile.works.map { |work| CiteProc.process(work.to_citeproc, :style => style) }.join("\n")
    end
  end
end