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

set :public, '/home/nico/phones/public'

get '/' do
    @phones = l.order(:sipnumber)
    
    haml :index
end

get '/:phonenumber' do
    phonenumber = params[:phonenumber]
    @phone = l.filter[:sipnumber => phonenumber]
    t = k.filter(:sipnumber => phonenumber).all
    @keys={}
    
    (0..11).to_a.each { |a|
        @keys[a]='---'
    }
    
    t.each { |key|
            @keys[key[:keynumber]]=key[:sipdestination]
    }
    
    haml :phone
end

# easily update a function key from JS box
get '/:phonenumber/update/:keynumber/:value?' do
    phonenumber=params[:phonenumber]
    keynumber=params[:keynumber]
    value=params[:value]
    
    key = k.filter(:sipnumber => phonenumber, :keynumber => keynumber)
    if !key.all.empty? then #update
        key.update(:sipdestination => value)
    else # add new value
        k.insert(:id => "", :sipnumber => phonenumber, :keynumber => keynumber, :sipdestination => value)
    end
    
    redirect '/'+params[:phonenumber].to_s
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
    @keys = k.filter(:sipnumber => @phone[:sipnumber].to_s).all
    
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

    @keys.each { |key|
        config += "fkey"+(key[:keynumber].to_s)+"!: dest <sip:"+(key[:sipdestination].to_s)+"@"+c["sipserver"]+";user=phone>\n"
    }

    config

end



