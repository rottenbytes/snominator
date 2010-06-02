function update_key(sipnumber, keynumber)
{
    var keyvalue = prompt("Saisissez la nouvelle valeur",null);
    
    window.location.replace("/"+sipnumber+"/update/"+keynumber+"/"+keyvalue);
}
