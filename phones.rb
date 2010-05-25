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
#k=DB[:md_phones_keys]

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
    
    # update these fields  
    [:sipnumber, :nom, :email, :sippassword, :mac].each { |entry|
        l.filter(:id => id).update(entry => params[entry])
    }
    
    redirect '/'+params[:sipnumber].to_s
end

get '/config/:mac' do
    content_type 'text/plain'

    mac = params[:mac]
    @phone = l.filter[:mac => mac]
    
    # Show config here (with haml, pure text)
    config = "language&: Francais
tone_scheme!: GER
no_dnd&: on\n"
    config += "ntp_server!: " + c["ntpserver"]+"\n"
    config += "dhcp&: on
silence_compression!: off
timezone&: FRA+1
date_us_format&: off
time_24_format&: on
user_active1!: on\n"
    config += "user_name1!: "+ (@phone[:sipnumber].to_s) +"\n"
    config += "user_host1!: "+ c["sipserver"] +"\n"
    config += "user_pname1!: "+ (@phone[:sipnumber].to_s) +"\n"
    config += "user_mailbox1!: *1\n"
    config += "user_idle_text1!: "+ (@phone[:nom].to_s) +"\n"
    config += "user_outbound1!: "+ c["sipserver"]+"\n"
    config += "record_missed_calls1!: on\n"
    config += "user_pass1!: "+ (@phone[:sippassword].to_s) +"\n"
    config += "phone_name!: "+ (@phone[:nom].to_s) +"\n"
    config += "user_realname1!: "+ (@phone[:nom].to_s) +"\n"


    config

end



