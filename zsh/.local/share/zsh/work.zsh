# work.zsh - Job/project-specific aliases and functions.
#
# These assume a particular project layout or workflow (a Maven/Spring Boot
# project, an Angular project with a local ssl/ folder, Office Add-in dev),
# not just "this machine" — but nothing here is secret. If it were (network
# details, client/company names), it belongs in local.zsh instead, which is
# gitignored. See readme.md.

alias rca="mvn spring-boot:run '-Dspring-boot.run.jvmArguments=-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005'"

alias roa="npx ng serve --port 4200 --ssl true --ssl-key ssl/localhost-key.pem --ssl-cert ssl/localhost.pem"

# Office Add-in dev cert: (re)install office-addin-dev-certs and trust the CA root
# for SSL so Chrome stops throwing ERR_CERT_AUTHORITY_INVALID on localhost.
# Certs expire ~30 days; re-run when the add-in icons/pane fail to load.
office-cert-fix() {
  npx --yes office-addin-dev-certs install || return 1
  security add-trusted-cert -r trustRoot -p ssl -k "$HOME/Library/Keychains/login.keychain-db" "$HOME/.office-addin-dev-certs/ca.crt" && echo "Office CA trusted for SSL - fully quit Chrome (Cmd+Q) and reopen."
}
alias fix-office-cert='office-cert-fix'
