namespace :load do
    task :defaults do
        set :nginx_server_name, -> { :default }
        set :socket_path, -> { '/var/run' }
        set :upstream_roles, -> { :web }
        set :upstream, -> { true }
        set :upstream_socket, -> { File.join(fetch(:socket_path),"#{ fetch(:server_name) }-fpm.sock") }
        set :upstream_template, -> { :default }
        set :upstream_config_dir, -> { '/etc/php5/fpm/pool.d' }
    end
end

namespace :deploy do
    namespace :nginx do
        namespace :site do
            namespace :upstream do
                desc 'Validate upstream provider configuration.'
                task :validate do
                    on release_roles fetch(:upstream_roles) do
                        sudo "php5-fpm -T"
                    end
                end

                desc 'Configure upstream provider.'
                task :configure do
                    on release_roles fetch(:upstream_roles) do
                        ## render template
                        pool_file = File.expand_path('../../templates/php5/fpm/pool.d/www.conf.erb', __FILE__)

                        if !(File.exists?(pool_file))
                            abort("Unable to locate pool configuration")
                        end

                        config = ERB.new(File.read(pool_file)).result(binding)
                        dest_filename = "/tmp/www.conf"
                        upload! StringIO.new(config), dest_filename
                        sudo :mv, dest_filename, fetch(:upstream_config_dir)
                    end
                end

                desc 'Install package dependencies from repository.'
                task :install_prereqs do
                    on release_roles fetch(:upstream_roles) do
                        execute "sudo apt-get install -yq php5-fpm php5-gd"
                    end
                end

                desc 'Start upstream provider daemon.'
                task :start => ['upstream:validate'] do
                    on release_roles fetch(:nginx_roles) do
                        if test('[ -f /etc/init/php5-fpm.conf ]')
                            sudo :service, "php5-fpm", "start"
                        else
                            abort('Unable to start upstream. Init file does not exist.')
                        end
                    end
                end
                desc 'Stop upstream provider daemon.'
                task :stop do
                    on release_roles fetch(:nginx_roles) do
                        if test('[ -f /etc/init/php5-fpm.conf ]')
                            sudo :service, 'php5-fpm', 'stop'
                        else
                            abort('Unable to stop upstream. Init file does not exist.')
                        end
                    end
                end

                desc 'Restart upstream daemon.'
                task :restart do
                    on release_roles fetch(:nginx_roles) do
                        if test('[ -f /etc/init/php5-fpm.conf ]')
                            sudo :service, 'php5-fpm', 'restart'
                        else
                            abort('Unable to restart upstream. Init file does not exist.')
                        end
                    end
                end
            end
        end
    end
end
