import openai
from elasticsearch import Elasticsearch
from elasticsearch.exceptions import NotFoundError, ConnectionError

# Configurações da API do OpenAI
openai.api_key = 'OPENAI_API_KEY'
model = "gpt-3.5-turbo"

# Caminho para o certificado CA
ca_certs_path = 'http_ca.crt'

# Configurações de conexão
es = Elasticsearch(
    hosts=[{'host': 'localhost', 'port': 9200, 'scheme': 'https'}],
    basic_auth=('elastic', 'ELASTIC_PASSWORD'),
    verify_certs=True,
    ca_certs=ca_certs_path  # Fornece o caminho para o certificado CA
)

def check_connection():
    try:
        # Verifica a conexão com o Elasticsearch
        if es.ping():
            print("Conectado ao Elasticsearch")
        else:
            print("Falha ao conectar ao Elasticsearch")
    except Exception as e:
        print(f"Erro ao conectar ao Elasticsearch: {e}")

def list_logs(index_name, size=10):
    try:
        # Realiza a busca no índice especificado, ordenando pelos mais recentes
        response = es.search(
            index=index_name,
            body={
                "query": {
                    "match_all": {}
                },
                "size": size,
                "sort": [{"@timestamp": {"order": "desc"}}]  # Ordena pelos logs mais recentes
            }
        )

        # Extrai e retorna os logs
        logs = response['hits']['hits']
        log_entries = [log['_source'] for log in logs]
        return log_entries
    except NotFoundError:
        print(f"Índice {index_name} não encontrado.")
    except ConnectionError as e:
        print(f"Erro de conexão: {e}")
    except Exception as e:
        print(f"Erro ao buscar logs: {e}")

def show_menu():
    print("Selecione o tipo de log:")
    print("1. Elastic Agent")
    print("2. Sistema")
    print("3. Docker")
    print("4. MySQL")
    print("5. Apache")

    choice = input("Digite o número da sua escolha: ")
    return choice

def get_index_name(choice):
    indices = {
        '1': '.ds-logs-elastic_agent*',
        '2': '.ds-logs-system.syslog-*',
        '3': '.ds-logs-docker*',
        '4': '.ds-logs-mysql*',
        '5': ['.ds-logs-apache*', '.ds-logs-apache.access-default*']
    }
    return indices.get(choice)

def analyze_logs(logs):
    try:
        log_texts = "\n".join(str(log) for log in logs)
        # Limitar o tamanho da string para evitar exceder o limite de tokens
        max_chars = 5000
        if len(log_texts) > max_chars:
            log_texts = log_texts[:max_chars]

        response = openai.ChatCompletion.create(
            model=model,
            messages=[
                {"role": "system", "content": "Você é um assistente útil."},
                {"role": "user", "content": f"Analise os seguintes logs e forneça um resumo em português:\n\n{log_texts}"}
            ],
            max_tokens=150,
            n=1,
            stop=None,
            temperature=0.7
        )
        analysis = response.choices[0].message['content'].strip()
        return analysis
    except Exception as e:
        return f"Erro ao analisar logs: {e}"

# Verifica a conexão antes de listar os logs
check_connection()

# Exibe o menu e captura a escolha do usuário
choice = show_menu()

# Obtém o índice correspondente à escolha do usuário
index_names = get_index_name(choice)

if index_names:
    # Caso o índice seja uma lista, busca logs para cada índice
    logs_to_analyze = []
    if isinstance(index_names, list):
        for index_name in index_names:
            print(f"Exibindo logs para o índice: {index_name}")
            logs = list_logs(index_name, size=10)  # Ajuste o tamanho conforme necessário
            if logs:
                logs_to_analyze.extend(logs)
    else:
        print(f"Exibindo logs para o índice: {index_names}")
        logs = list_logs(index_names, size=10)  # Ajuste o tamanho conforme necessário
        if logs:
            logs_to_analyze.extend(logs)

    if logs_to_analyze:
        analysis = analyze_logs(logs_to_analyze)
        print(f"Análise dos logs:\n{analysis}")
else:
    print("Escolha inválida.")
