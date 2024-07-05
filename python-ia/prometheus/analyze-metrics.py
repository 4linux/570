import requests
import pandas as pd
import openai
import matplotlib.pyplot as plt

# Função para obter a lista de jobs do Prometheus filtrados pela porta 9100
def get_prometheus_jobs(prometheus_url):
    response = requests.get(f"{prometheus_url}/api/v1/targets")
    data = response.json()
    if data['status'] == 'success':
        jobs = sorted(set(
            item['labels']['job'] for item in data['data']['activeTargets']
            if ':9100' in item['labels']['instance']
        ))
        return jobs
    else:
        raise Exception(f"Erro ao consultar os jobs do Prometheus: {data}")

# Função para coletar métricas do Prometheus
def get_prometheus_metrics(prometheus_url, query, start, end):
    response = requests.get(f"{prometheus_url}/api/v1/query_range", params={
        'query': query,
        'start': start,
        'end': end,
        'step': '300s'  # Ajuste conforme necessário
    })
    data = response.json()
    if data['status'] == 'success':
        results = data['data']['result']
        metrics = []
        for result in results:
            metric = result['metric']
            values = result['values']
            for value in values:
                metrics.append({
                    'instance': metric.get('instance', 'unknown'),
                    'job': metric.get('job', 'unknown'),
                    'value': float(value[1]),
                    'timestamp': pd.to_datetime(float(value[0]), unit='s')
                })
        return pd.DataFrame(metrics)
    else:
        raise Exception(f"Erro ao consultar o Prometheus: {data}")

# Função para obter análise do ChatGPT
def get_chatgpt_analysis(data, openai_api_key):
    openai.api_key = openai_api_key
    data_summary = data.describe().to_dict()  # Obtendo estatísticas descritivas dos dados
    sample_data = data.sample(n=5).to_dict(orient='records')  # Amostragem de alguns pontos de dados
    response = openai.ChatCompletion.create(
        model="gpt-3.5-turbo",
        messages=[
            {"role": "system", "content": "Você é um assistente especializado em análise de métricas."},
            {"role": "user", "content": (
                f"Por favor, analise os seguintes dados de métricas:\n"
                f"Resumo estatístico: {data_summary}\n"
                f"Amostras de dados: {sample_data}\n"
                f"Gostaria de uma análise detalhada desses dados, incluindo tendências, anomalias e possíveis interpretações."
            )}
        ]
    )
    return response.choices[0].message['content']

# Configurações do Prometheus e API do ChatGPT
prometheus_url = "http://localhost:9090"
openai_api_key = 'INSIRA_AQUI_A_CHAVE_DO_OPENAI'

# Obtém a lista de jobs do Prometheus
try:
    jobs = get_prometheus_jobs(prometheus_url)
    if not jobs:
        print("Nenhum job encontrado no Prometheus.")
        exit(1)
except Exception as e:
    print(e)
    exit(1)

# Exibe a lista de jobs para o usuário selecionar
print("Selecione o job para análise:")
for idx, job in enumerate(jobs, start=1):
    print(f"{idx}. {job}")

job_selection = input("Digite o número do job selecionado:\n")
try:
    job_index = int(job_selection) - 1
    if job_index < 0 or job_index >= len(jobs):
        raise ValueError("Seleção de job inválida.")
    job_name = jobs[job_index]
except ValueError as e:
    print(e)
    exit(1)

# Tipos de métricas disponíveis
metric_types = ['CPU', 'Memória', 'Disco', 'Processos']

# Exibe a lista de tipos de métricas para o usuário selecionar
print("Selecione o tipo de métrica para análise:")
for idx, metric in enumerate(metric_types, start=1):
    print(f"{idx}. {metric}")

metric_selection = input("Digite o número do tipo de métrica selecionado:\n")
try:
    metric_index = int(metric_selection) - 1
    if metric_index < 0 or metric_index >= len(metric_types):
        raise ValueError("Seleção de métrica inválida.")
    metric_type = metric_types[metric_index].lower()
except ValueError as e:
    print(e)
    exit(1)

# Configurações do intervalo de tempo para coleta de dados
end_time = pd.Timestamp.now()
start_time = end_time - pd.Timedelta(hours=1)  # Coletando dados da última hora

# Queries para métricas específicas
queries = {
    'cpu': f'rate(node_cpu_seconds_total{{job="{job_name}",mode="idle"}}[5m])',
    'memória': f'node_memory_MemAvailable_bytes{{job="{job_name}"}} / node_memory_MemTotal_bytes{{job="{job_name}"}}',
    'disco': f'rate(node_disk_io_time_seconds_total{{job="{job_name}"}}[5m])',
    'processos': f'node_procs_running{{job="{job_name}"}}'
}

# Verifica se a métrica informada é válida
if metric_type not in queries:
    print("Tipo de métrica inválido. Por favor, escolha entre CPU, Memória, Disco ou Processos.")
    exit(1)

# Coleta de métricas do Prometheus
try:
    query = queries[metric_type]
    df = get_prometheus_metrics(prometheus_url, query, start_time.timestamp(), end_time.timestamp())
    df['metric_name'] = metric_type.capitalize()
    print(df)
except Exception as e:
    print(e)
    exit(1)

# Visualização da métrica
df.set_index('timestamp', inplace=True)
df.groupby('instance')['value'].plot(legend=True, title=metric_type.capitalize())
plt.xlabel('Timestamp')
plt.ylabel('Value')
plt.title(f'{metric_type.capitalize()} Usage')
plt.show()

# Análise com ChatGPT
try:
    analysis = get_chatgpt_analysis(df, openai_api_key)
    print("Análise do ChatGPT:")
    print(analysis)
except Exception as e:
    print(f"Erro ao consultar a API do ChatGPT: {e}")
