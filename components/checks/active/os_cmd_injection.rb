=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

# Simple OS command injection check.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.2.1
#
# @see http://cwe.mitre.org/data/definitions/78.html
# @see http://www.owasp.org/index.php/OS_Command_Injection
class Arachni::Checks::OsCmdInjection < Arachni::Check::Base

    def self.options
        @options ||= {
            regexp: {
                unix: [
                    /(root|mail):.+:\d+:\d+:.+:[0-9a-zA-Z\/]+/im
                ],
                windows: [
                    /\[boot loader\](.*)\[operating systems\]/im,
                    /\[fonts\](.*)\[extensions\]/im
                ]
            },
            format: [ Format::STRAIGHT, Format::APPEND ]
        }
    end

    def self.payloads
        @payloads ||= {
            unix:    [
                '/bin/cat /etc/passwd'
            ],
            aix: [
                '/bin/cat /etc/security/passwd'
            ],
            bsd: [
                '/bin/cat /etc/master.passwd',
            ],
            windows: [
                'type %SystemDrive%\\\\boot.ini',
                'type %SystemRoot%\\\\win.ini'
            ]
        }.inject({}) do |h, (platform, payloads)|
            h[platform] ||= []
            payloads.each do |payload|
                h[platform] |= [ '', '&&', '|', ';' ].map { |sep| "#{sep} #{payload}" }
                h[platform] << "` #{payload}`"
            end
            h
        end
    end

    def run
        audit self.class.payloads, self.class.options
    end

    def self.info
        {
            name:        'OS command injection',
            description: %q{
Tries to find Operating System command injections.
},
            elements:    [ Element::Form, Element::Link, Element::Cookie,
                           Element::Header, Element::LinkTemplate ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.2.1',
            platforms:   payloads.keys,

            issue:       {
                name:            %q{Operating system command injection},
                description:     %q{
To perform specific actions from within a web application, it is occasionally
required to run Operating System commands and have the output of these commands
captured by the web application and returned to the client.

OS command injection occurs when user supplied input is inserted into one of these
commands without proper sanitisation and is then executed by the server.

Cyber-criminals will abuse this weakness to perform their own arbitrary commands
on the server. This can include everything from simple `ping` commands to map the
internal network, to obtaining full control of the server.

Arachni was able to inject specific Operating System commands and have the output
from that command contained within the server response. This indicates that proper
input sanitisation is not occurring.
},
                references:  {
                    'OWASP' => 'http://www.owasp.org/index.php/OS_Command_Injection',
                    'WASC'  => 'http://projects.webappsec.org/w/page/13246950/OS%20Commanding'
                },
                tags:            %w(os command code injection regexp error),
                cwe:             78,
                severity:        Severity::HIGH,
                remedy_guidance: %q{
It is recommended that untrusted data is never used to form a command to be
executed by the OS.

To validate data, the application should ensure that the supplied value contains
only the characters that are required to perform the required action.

For example, where the form field expects an IP address, only numbers and periods
should be accepted. Additionally, all control operators (`&`, `&&`, `|`, `||`,
`$`, `\`, `#`) should be explicitly denied and never accepted as valid input by
the server.
},
            }
        }
    end

end
