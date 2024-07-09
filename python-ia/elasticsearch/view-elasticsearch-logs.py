from elasticsearch import Elasticsearch
from elasticsearch.exceptions import NotFoundError, ConnectionError

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
        # Realiza a busca no índice especificado
        response = es.search(
            index=index_name,
            body={
                "query": {
                    "match_all": {}
                },
                "size": size
            }
        )

        # Extrai e imprime os logs
        logs = response['hits']['hits']
        for log in logs:
            print(f"ID: {log['_id']}")
            print(f"Source: {log['_source']}")
            print("-----")
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

# Verifica a conexão antes de listar os logs
check_connection()

# Exibe o menu e captura a escolha do usuário
choice = show_menu()

# Obtém o índice correspondente à escolha do usuário
index_names = get_index_name(choice)

if index_names:
    # Caso o índice seja uma lista, busca logs para cada índice
    if isinstance(index_names, list):
        for index_name in index_names:
            print(f"Exibindo logs para o índice: {index_name}")
            list_logs(index_name)
    else:
        print(f"Exibindo logs para o índice: {index_names}")
        list_logs(index_names)
else:
    print("Escolha inválida.")
