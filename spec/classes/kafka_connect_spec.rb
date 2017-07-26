require 'spec_helper'


%w(distributed standalone).each do |class_name|
  describe "confluent::kafka::connect::#{class_name}" do
    supported_osfamalies.each do |osfamily, osversions|
      osversions.each do |osversion|
        context "with osfamily => #{osfamily} and operatingsystemmajrelease => #{osversion}" do
          default_facts = {
              'osfamily' => osfamily,
              'operatingsystemmajrelease' => osversion
          }
          default_params = {
              'config' => {
                  'bootstrap.servers' => {
                      'value' => 'kafka-01:9093'
                  }
              }
          }
          let(:params) {default_params}
          let(:facts) {default_facts}

          environment_file = nil

          case osfamily
            when 'Debian'
              environment_file = "/etc/default/kafka-connect-#{class_name}"
            when 'RedHat'
              environment_file = "/etc/sysconfig/kafka-connect-#{class_name}"
          end

          expected_heap = '-Xmx256M'

          log_dirs = ["/var/log/kafka-connect-#{class_name}", "/app/var/log/kafka-connect-#{class_name}"]

          log_dirs.each do |log_dir|
            context "with param log_dir = '#{log_dir}'" do
              let(:params) {
                default_params.merge({'log_path' => log_dir})
              }
              it {
                is_expected.to contain_ini_subsetting("connect-#{class_name}_LOG_DIR").with(
                    {
                        'path' => environment_file,
                        'value' => log_dir
                    }
                )
              }
              it {
                is_expected.to contain_file(log_dir).with(
                    {
                        'owner' => "connect-#{class_name}",
                        'group' => "connect-#{class_name}",
                        'recurse' => true
                    }
                )
              }
              it {is_expected.to contain_package('confluent-kafka-2.11')}
              it {is_expected.to contain_ini_setting("connect-#{class_name}_bootstrap.servers").with(
                  {
                      'path' => "/etc/kafka/connect-#{class_name}.properties",
                      'value' => 'kafka-01:9093'
                  }
              )
              }
              it {
                is_expected.to contain_user("connect-#{class_name}")
              }
              it {
                is_expected.to contain_service("connect-#{class_name}").with(
                    {
                        'ensure' => 'running',
                        'enable' => true
                    }
                )
              }
              it {
                is_expected.to contain_ini_subsetting("connect-#{class_name}_KAFKA_HEAP_OPTS").with(
                    {
                        'path' => environment_file,
                        'value' => expected_heap
                    }
                )
              }
            end
          end
        end
      end
    end
  end
end
# end