#!/usr/bin/expect -f
set ip [ lindex $argv 0 ]
set user [ lindex $argv 1 ]
set password [ lindex $argv 2 ]
set port [ lindex $argv 3 ]
set host [ lindex $argv 4 ]
set ftpip [ lindex $argv 5 ]
set ftpuser [ lindex $argv 6 ]
set ftppwd [ lindex $argv 7 ]
spawn ssh -p $port $user@$ip
expect {
	"(yes/no)?"
		{
			send "yes\r"
			expect "password:"
			send "$password\r"
		}
	"password:"
	{
		send "$password\r"
	}
}
expect "*#"
send "export configuration startup to ftp server $ftpip user $ftpuser password $ftppwd $host\r"
expect "Export ok"
send "exit\r"
expect eof
