#!/bin/bash
httpcode() {
	if [ -z "$1" ]; then
		echo "Uso: httpcode <codigo_http>"
		echo "Exemplo: httpcode 404"
		return 1
	fi

	case $1 in
	# ==========================================
	# 1xx - INFORMATIVOS (Padrão)
	# ==========================================
	100) echo -e "100 Continue\nO cliente deve continuar com sua requisição." ;;
	101) echo -e "101 Switching Protocols\nO servidor aceita a troca de protocolo (ex: WebSockets)." ;;
	102) echo -e "102 Processing (WebDAV)\nO servidor está processando a requisição, sem resposta disponível ainda." ;;
	103) echo -e "103 Early Hints\nRetorna cabeçalhos antes da resposta final para pré-carregamento." ;;

	# ==========================================
	# 2xx - SUCESSO (Padrão)
	# ==========================================
	200) echo -e "200 OK\nA requisição foi bem-sucedida." ;;
	201) echo -e "201 Created\nRequisição bem-sucedida e um novo recurso foi criado." ;;
	202) echo -e "202 Accepted\nRequisição aceita para processamento, mas não concluída." ;;
	203) echo -e "203 Non-Authoritative Information\nA resposta foi gerada por um proxy a partir de um cache." ;;
	204) echo -e "204 No Content\nRequisição bem-sucedida, sem conteúdo no corpo da resposta." ;;
	205) echo -e "205 Reset Content\nSolicita que o cliente limpe/redefina a visualização (ex: formulário)." ;;
	206) echo -e "206 Partial Content\nA resposta contém apenas parte do recurso (ex: download pausado)." ;;
	207) echo -e "207 Multi-Status (WebDAV)\nTransmite mensagens sobre múltiplos recursos na mesma resposta." ;;
	208) echo -e "208 Already Reported (WebDAV)\nOs membros de uma coleção já foram enumerados na resposta anterior." ;;
	226) echo -e "226 IM Used\nO servidor cumpriu um GET e a resposta é resultado de manipulações de instância." ;;

	# Não-oficiais de Sucesso
	218) echo -e "218 This is fine (Apache)\nUsado como um catch-all não-oficial em proxies para forçar o roteamento de erros pela rede." ;;

	# ==========================================
	# 3xx - REDIRECIONAMENTO (Padrão)
	# ==========================================
	300) echo -e "300 Multiple Choices\nHá mais de uma opção de recurso que o cliente pode escolher." ;;
	301) echo -e "301 Moved Permanently\nO recurso foi movido definitivamente para uma nova URI." ;;
	302) echo -e "302 Found\nO recurso foi movido temporariamente para uma nova URI." ;;
	303) echo -e "303 See Other\nA resposta pode ser encontrada em outra URI via método GET." ;;
	304) echo -e "304 Not Modified\nO recurso não foi modificado desde a última requisição (usado em Cache)." ;;
	305) echo -e "305 Use Proxy (Obsoleto)\nO recurso solicitado deve ser acessado através de um proxy." ;;
	306) echo -e "306 Switch Proxy / Unused\nCódigo histórico não utilizado mais. Originalmente pedia troca de proxy." ;;
	307) echo -e "307 Temporary Redirect\nRedirecionamento temporário mantendo o método original (ex: POST continua POST)." ;;
	308) echo -e "308 Permanent Redirect\nRedirecionamento permanente mantendo o método original." ;;

	# ==========================================
	# 4xx - ERROS DO CLIENTE (Padrão)
	# ==========================================
	400) echo -e "400 Bad Request\nRequisição malformada ou sintaxe inválida." ;;
	401) echo -e "401 Unauthorized\nRequer autenticação para acessar o recurso." ;;
	402) echo -e "402 Payment Required\nReservado para uso futuro (usado por algumas APIs para limite de cota)." ;;
	403) echo -e "403 Forbidden\nO servidor entende a requisição, mas se recusa a autorizá-la (falta de permissão)." ;;
	404) echo -e "404 Not Found\nO recurso solicitado não foi encontrado." ;;
	405) echo -e "405 Method Not Allowed\nO método HTTP (GET, POST, etc.) não é suportado pelo recurso." ;;
	406) echo -e "406 Not Acceptable\nNenhum conteúdo aceitável de acordo com os cabeçalhos 'Accept'." ;;
	407) echo -e "407 Proxy Authentication Required\nO cliente deve se autenticar no proxy primeiro." ;;
	408) echo -e "408 Request Timeout\nO tempo de espera do servidor pela requisição expirou." ;;
	409) echo -e "409 Conflict\nConflito com o estado atual do recurso (ex: criar usuário que já existe)." ;;
	410) echo -e "410 Gone\nO recurso não está mais disponível e não há endereço de redirecionamento." ;;
	411) echo -e "411 Length Required\nO servidor exige o cabeçalho 'Content-Length'." ;;
	412) echo -e "412 Precondition Failed\nUma ou mais pré-condições nos cabeçalhos falharam." ;;
	413) echo -e "413 Payload Too Large\nO corpo da requisição é maior do que o servidor aceita." ;;
	414) echo -e "414 URI Too Long\nA URL da requisição é muito longa para o servidor processar." ;;
	415) echo -e "415 Unsupported Media Type\nO formato do payload não é suportado (ex: enviou XML em vez de JSON)." ;;
	416) echo -e "416 Range Not Satisfiable\nO trecho solicitado do arquivo (Range) não pode ser fornecido." ;;
	417) echo -e "417 Expectation Failed\nA expectativa indicada no cabeçalho 'Expect' não pôde ser atendida." ;;
	418) echo -e "418 I'm a teapot\nEu sou um bule (RFC 2324 - Brincadeira de 1º de abril do IETF)." ;;
	421) echo -e "421 Misdirected Request\nA requisição foi direcionada a um servidor incapaz de responder." ;;
	422) echo -e "422 Unprocessable Entity (WebDAV)\nRequisição bem formada, mas possui erros semânticos (ex: validação de dados falhou)." ;;
	423) echo -e "423 Locked (WebDAV)\nO recurso acessado está trancado." ;;
	424) echo -e "424 Failed Dependency (WebDAV)\nA requisição falhou devido a uma falha em uma requisição anterior." ;;
	425) echo -e "425 Too Early\nO servidor recusa processar por risco de ataque de repetição (Replay Attack)." ;;
	426) echo -e "426 Upgrade Required\nO cliente deve mudar para um protocolo diferente (ex: TLS)." ;;
	428) echo -e "428 Precondition Required\nO servidor requer que a requisição seja condicional." ;;
	429) echo -e "429 Too Many Requests\nLimite de taxa (Rate Limiting). O cliente enviou requisições demais." ;;
	431) echo -e "431 Request Header Fields Too Large\nOs campos de cabeçalho da requisição são muito grandes." ;;
	451) echo -e "451 Unavailable For Legal Reasons\nRecurso indisponível por motivos legais (censura, direitos autorais)." ;;

	# Não-oficiais de Cliente (Nginx, IIS, AWS, Frameworks)
	419) echo -e "419 Page Expired (Laravel)\nA sessão expirou ou o token CSRF é inválido/ausente." ;;
	420) echo -e "420 Enhance Your Calm (Twitter) / Method Failure (Spring)\nTwitter: Limite de taxa (piada). / Spring: Falha na execução do método." ;;
	430) echo -e "430 Request Header Fields Too Large (Shopify)\nVariação não-oficial do Shopify para o erro 431." ;;
	440) echo -e "440 Login Time-out (IIS)\nA sessão do cliente expirou e ele deve fazer login novamente." ;;
	444) echo -e "444 No Response (Nginx)\nO servidor fechou a conexão sem enviar reposta (usado contra malwares)." ;;
	449) echo -e "449 Retry With (IIS)\nA requisição deve ser repetida após realizar a ação apropriada." ;;
	450) echo -e "450 Blocked by Windows Parental Controls (Microsoft)\nO acesso foi bloqueado pelos Controles dos Pais do Windows." ;;
	460) echo -e "460 Client Closed Connection (AWS ELB)\nO cliente fechou a conexão antes do load balancer da AWS poder responder." ;;
	463) echo -e "463 X-Forwarded-For Too Large (AWS ELB)\nO load balancer recebeu mais de 30 IPs no cabeçalho X-Forwarded-For." ;;
	464) echo -e "464 Incompatible Protocol (AWS ELB)\nO protocolo da requisição é incompatível com a configuração do load balancer AWS." ;;
	494) echo -e "494 Request header too large (Nginx)\nCliente enviou cabeçalho muito grande." ;;
	495) echo -e "495 SSL Certificate Error (Nginx)\nErro no certificado SSL fornecido pelo cliente." ;;
	496) echo -e "496 SSL Certificate Required (Nginx)\nO cliente não forneceu o certificado SSL obrigatório." ;;
	497) echo -e "497 HTTP Request Sent to HTTPS Port (Nginx)\nCliente tentou fazer requisição HTTP simples em porta HTTPS." ;;
	498) echo -e "498 Invalid Token (Esri / macOS Server)\nO token fornecido expirou ou é inválido." ;;
	499) echo -e "499 Client Closed Request (Nginx)\nO cliente (ou navegador) fechou a conexão antes do Nginx responder." ;;

	# ==========================================
	# 5xx - ERROS DO SERVIDOR (Padrão)
	# ==========================================
	500) echo -e "500 Internal Server Error\nErro genérico inesperado no código do lado do servidor." ;;
	501) echo -e "501 Not Implemented\nO servidor não suporta a funcionalidade para atender a requisição." ;;
	502) echo -e "502 Bad Gateway\nO servidor atuando como proxy recebeu uma resposta inválida do servidor upstream." ;;
	503) echo -e "503 Service Unavailable\nO servidor está sobrecarregado ou em manutenção temporária." ;;
	504) echo -e "504 Gateway Timeout\nO servidor atuando como proxy não recebeu uma resposta a tempo do upstream." ;;
	505) echo -e "505 HTTP Version Not Supported\nA versão do protocolo HTTP usada não é suportada." ;;
	506) echo -e "506 Variant Also Negotiates\nErro de configuração de negociação de conteúdo no servidor." ;;
	507) echo -e "507 Insufficient Storage (WebDAV)\nO servidor não tem espaço suficiente para armazenar o recurso." ;;
	508) echo -e "508 Loop Detected (WebDAV)\nO servidor detectou um loop infinito (ex: redirecionamentos cíclicos)." ;;
	510) echo -e "510 Not Extended\nMais extensões para a requisição são necessárias para o servidor atendê-la." ;;
	511) echo -e "511 Network Authentication Required\nO cliente precisa se autenticar na rede para ganhar acesso à internet (ex: Wi-Fi público)." ;;

	# Não-oficiais de Servidor (Cloudflare, AWS, Apache)
	509) echo -e "509 Bandwidth Limit Exceeded (Apache/cPanel)\nO site ultrapassou o limite de tráfego/banda do provedor de hospedagem." ;;
	520) echo -e "520 Web Server Returned an Unknown Error (Cloudflare)\nO servidor de origem retornou resposta vazia ou inexplicável." ;;
	521) echo -e "521 Web Server Is Down (Cloudflare)\nO servidor de origem recusou a conexão." ;;
	522) echo -e "522 Connection Timed Out (Cloudflare)\nFalha ao negociar TCP handshake com a origem." ;;
	523) echo -e "523 Origin Is Unreachable (Cloudflare)\nServidor de origem inacessível (ex: erro de DNS ou rota)." ;;
	524) echo -e "524 A Timeout Occurred (Cloudflare)\nConexão TCP completada, mas a origem não respondeu a tempo." ;;
	525) echo -e "525 SSL Handshake Failed (Cloudflare)\nFalha ao negociar SSL/TLS com o servidor de origem." ;;
	526) echo -e "526 Invalid SSL Certificate (Cloudflare)\nO servidor de origem está usando um certificado SSL inválido." ;;
	527) echo -e "527 Railgun Error (Cloudflare)\nFalha na conexão WAN (Railgun) com o servidor de origem." ;;
	529) echo -e "529 Site is overloaded (Qualys)\nO serviço está temporariamente sobrecarregado (comum em APIs de análise)." ;;
	530) echo -e "530 Origin DNS Error (Cloudflare) / Site is frozen (Pantheon)\nErro de DNS na Cloudflare ou site inativo em plataformas como Pantheon." ;;
	561) echo -e "561 Unauthorized (AWS ELB)\nErro de autenticação no provedor de identidade (IdP) vinculado ao load balancer." ;;
	598) echo -e "598 Network read timeout error (Informal)\nTimeout de leitura de rede em alguns proxies HTTP." ;;
	599) echo -e "599 Network connect timeout error (Informal)\nTimeout de conexão de rede em alguns proxies HTTP." ;;

	# ==========================================
	# CÓDIGO NÃO RECONHECIDO
	# ==========================================
	*) echo -e "Código $1 não reconhecido.\nVerifique se o número foi digitado corretamente." ;;
	esac
}
httpcode "$1"
