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

get '/' do
  markdown :index
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
    format.xml { @profile.works.to_xml(:extended => true) }
    format.json { @profile.works.to_citeproc.to_json }
    format.yml { @profile.works.to_citeproc.to_yaml }
    format.txt { @profile.works.map { |work| CiteProc.process(work.to_citeproc, :style => get_csl(params[:style])) }.join("\n") }
  end
end
