import requests
import pandas as pd
import matplotlib.pyplot as plt

# Defina a URL do seu servidor Prometheus
prometheus_url = "http://localhost:9090/api/v1/query"

# Defina a consulta Prometheus que você deseja realizar
query = "up"

# Realize a consulta ao Prometheus
response = requests.get(prometheus_url, params={'query': query})
data = response.json()

# Verifique se a consulta foi bem-sucedida
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
    plt.title('Prometheus Metrics')
    plt.show()
else:
    print("Erro ao consultar o Prometheus:", data)
