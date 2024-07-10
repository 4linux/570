import requests
import pandas as pd
import matplotlib.pyplot as plt
import subprocess

# Defina a URL do seu servidor Prometheus
prometheus_url = "http://localhost:9090/api/v1"

# Função para listar jobs disponíveis
def get_jobs():
    response = requests.get(f"{prometheus_url}/targets")
    data = response.json()
    if data['status'] == 'success':
        jobs = set()
        for target in data['data']['activeTargets']:
            jobs.add(target['labels']['job'])
        return list(jobs)
    else:
        print("Erro ao consultar os jobs do Prometheus:", data)
        return []

# Função para obter métricas de um job específico
def get_metrics(job):
    query = f'up{{job="{job}"}}'
    response = requests.get(f"{prometheus_url}/query", params={'query': query})
    return response.json()

# Função para mostrar menu de seleção de jobs
def select_job(jobs):
    print("Selecione um job:")
    for idx, job in enumerate(jobs):
        print(f"{idx + 1}. {job}")
    selected_index = int(input("Digite o número do job desejado: ")) - 1
    return jobs[selected_index]

# Função para visualizar as métricas usando curl
def visualize_metrics(instance):
    url = f"http://{instance}/metrics"
    subprocess.run(["curl", url])

# Listar jobs disponíveis
jobs = get_jobs()
if not jobs:
    print("Nenhum job disponível.")
    exit()

# Selecionar um job
selected_job = select_job(jobs)

# Obter métricas do job selecionado
data = get_metrics(selected_job)

# Verificar se a consulta foi bem-sucedida
if data['status'] == 'success':
    results = data['data']['result']
    
    # Extraia os dados e converta para um DataFrame do pandas
    metrics = []
    for result in results:
        metric = result['metric']
        value = result['value']
        metrics.append({
            'instance': metric.get('instance', 'unknown'),
            'job': metric.get('job', 'unknown'),
            'value': float(value[1]),
            'timestamp': pd.to_datetime(float(value[0]), unit='s')
        })

    df = pd.DataFrame(metrics)
    print(df)
    
    # Visualize as métricas com um gráfico
    df.set_index('timestamp', inplace=True)
    df.groupby('instance')['value'].plot(legend=True)
    plt.xlabel('Timestamp')
    plt.ylabel('Value')
    plt.title(f'Prometheus Metrics for Job: {selected_job}')
    plt.show()
    
    # Visualizar métricas na saída padrão usando curl
    for instance in df['instance'].unique():
        print(f"\nMétricas para a instância: {instance}")
        visualize_metrics(instance)
else:
    print("Erro ao consultar o Prometheus:", data)
