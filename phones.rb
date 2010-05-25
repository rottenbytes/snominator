require 'rubygems'
require 'sinatra'
require 'haml'
require 'sequel'

c=YAML::load(File.read("config.yaml"))

DB = Sequel.connect(:adapter => "mysql",
                    :host => c["host"],
                    :database => c["database"],
                    :user => c["user"],
                    :password => c["password"] )

l=DB[:md_phones]
k=DB[:md_phones_keys]

get '/' do
    @phones = l.order(:sipnumber)
    
    haml :index
end

get '/:phonenumber' do
    phonenumber = params[:phonenumber]
    @phone = l.filter[:sipnumber => phonenumber]
    @keys = k.filter[:sipnumber => phonenumber]
        
    haml :phone
end

post '/:phonenumber' do
    id = params[:id]
      
    [:sipnumber, :nom, :email, :sippassword, :mac].each { |entry|
        l.filter(:id => id).update(entry => params[entry])
    }
    
    redirect '/'+params[:sipnumber].to_s
end

get '/config/:mac' do
    mac = params[:mac]
    @phone = l.filter[:mac => mac]
    
end



