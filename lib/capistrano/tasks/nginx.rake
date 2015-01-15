namespace :load do
    task :defaults do
    end
end

namespace :deploy do
    namespace :nginx do

        desc 'Install nginx package prerequisites.'
        task :install do
            on release_roles fetch(:nginx_roles) do
                execute 'sudo', 'apt-get', 'install', '-qy', '--no-install-recommends', '--no-remove', 'nginx nginx-full'
            end
        end

        desc 'Start nginx daemon'
        task :start => ['deploy:nginx:site:validate'] do
            on release_roles fetch(:nginx_roles) do
                if test('[ -f /etc/init.d/nginx ]')
                    execute :service, 'nginx', 'restart'
                else
                    abort('There is no service nginx.')
                end
            end
        end

        desc 'Stop nginx daemon'
        task :stop do
            on release_roles fetch(:nginx_roles) do
                if test('[ -f /etc/init.d/nginx ]')
                    execute :service, 'nginx', 'stop'
                else
                    abort('There is no service nginx.')
                end
            end
        end

        desc 'Restart nginx dameon'
        task :restart => ['deploy:nginx:site:validate'] do
            on release_roles fetch(:nginx_roles) do
                if test('[ -f /etc/init.d/nginx ]')
                    execute :service, 'nginx', 'restart'
                else
                    abort('There is no service nginx.')
                end
            end
        end

    end
end
