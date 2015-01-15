namespace :load do
    task :defaults do
        set :socket_path, -> { '/var/run' }
        set :nginx_config_dir, -> { '/etc/nginx' }
        set :nginx_sites_available_dir, -> { 'sites-available' }
        set :nginx_sites_enabled_dir, -> { 'sites-enabled' }
        set :nginx_roles, -> { :web }
        set :nginx_server_name, -> { :default }
        set :nginx_wordpress, -> { false }
        set :nginx_statemic, -> { false }
        set :upstream, -> { true }
        set :upstream_socket, -> { File.join(fetch(:socket_path),"#{ fetch(:nginx_server_name) }-fpm.sock") }
    end
end

namespace :deploy do
    namespace :nginx do
        namespace :site do
            def valid_config?(site_config_path)
                if test("sudo nginx -t -c #{site_config_path}")
                    return true
                else
                    abort("Nginx site configuration is invalid. Cannot continue.")
                end
            end

            desc 'Validate nginx site configuration.'
            task :validate do
                on release_roles fetch(:nginx_roles) do
                    nginx_sites_enabled_dir = File.join(fetch(:nginx_config_dir),fetch(:nginx_sites_enabled_dir))
                    site_file = fetch(:nginx_server_name).to_s + ".conf"
                    site_path = File.join(nginx_sites_enabled_dir,site_file)
                    if !(test("[ -f #{site_path} ]"))
                        abort('Unable to locate site configuration to validate.')
                    end
                    valid_config?(site_path)
                end
            end

            desc 'Add nginx global configurations.'
            task :globals do
                on release_roles fetch(:nginx_roles) do
                    conf = File.join(fetch(:nginx_config_dir),'global')
                    sudo :mkdir, '-pv', conf.to_s

                    Dir.foreach(File.expand_path('../../templates/nginx/global')) do |global|
                        dest_filename = global.to_s.split('/').pop.sub(/\.conf\.erb/,'.conf')
                        rendered = ERB.new(File.read(global)).result(binding)
                        upload! StringIO.new(rendered), dest_filename
                        sudo :mv, '-fv', dest_filename, conf
                    end
                end
            end

            desc 'Add nginx site.'
            task :add => ['deploy:nginx:site:globals'] do
                on release_roles fetch(:nginx_roles) do
                    nginx_sites_available_dir = File.join(fetch(:nginx_config_dir),fetch(:nginx_sites_enabled_dir))
                    within nginx_sites_available_dir do
                        ## render template
                        site = fetch(:nginx_server_name)
                        if site == :default
                            site_file = File.expand_path('../../templates/nginx/default-nginx-site.conf.erb', __FILE__)
                        else
                            if fetch(:nginx_wordpress)
                                site_file = File.expand_path('../../templates/nginx/default-wordpress-site.conf.erb'. __FILE__)
                            elsif fetch(:nginx_statemic)
                                site_file = File.expand_path('../../templates/nginx/default-statemic-site.conf.erb'. __FILE__)
                            else
                                site_file = File.expand_path("../../templates/nginx/#{site.to_s}.conf.erb", __FILE__)
                            end
                        end

                        if !(File.exists?(site_file))
                            abort('Unable to locate site configuration for #{site}')
                        end

                        config = ERB.new(File.read(site_file)).result(binding)
                        dest_filename = "/tmp/#{site.to_s}.conf"
                        upload! StringIO.new(config), dest_filename
                        sudo :mv, dest_filename, nginx_sites_available_dir
                    end
                end
            end

            desc 'Enable nginx site.'
            task :enable => ['deploy:nginx:site:add'] do
                on release_roles fetch(:nginx_roles) do
                    en_dir  = File.join(fetch(:nginx_config_dir),fetch(:nginx_sites_enabled_dir))
                    av_dir  = File.join(fetch(:nginx_config_dir),fetch(:nginx_sites_available_dir))
                    site    = fetch(:nginx_server_name).to_s + ".conf"
                    en_site = File.join(en_dir,site)
                    av_site = File.join(av_dir,site)
                    within en_dir do
                        if test("[ -f #{av_site} ]")
                            if valid_config?(av_site)
                                sudo :ln, '-s', av_site.to_s, en_site.to_s
                            end
                        end
                    end
                end
            end

            desc 'Remove nginx site.'
            task :remove do
                on release_roles fetch(:nginx_roles) do
                    nginx_sites_enabled_path = FILE.join(fetch(:nginx_config_dir),fetch(:nginx_sites_enabled_dir))
                    within nginx_sites_enabled_path do
                        site_to_remove = fetch(:nginx_server_name).to_s + ".conf"
                        file_path = File.join(nginx_sites_enabled_path, site_to_remove)

                        if test("[ -f #{file_path} ]")
                            sudo :rm, '-fv', file_path
                            av_path = File.join(fetch(:nginx_config_dir), fetch(:nginx_sites_available_dir), site_to_remove)

                            if test("[ -f #{av_path} ]")
                                sudo :rm, '-fv', av_path
                            end
                        end
                    end
                end
            end
        end
    end
end
