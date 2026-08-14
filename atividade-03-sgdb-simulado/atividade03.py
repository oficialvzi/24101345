# Desafio 1
def parse_txt_file(filepath, delimiter=';'):
    try:
        with open(filepath, 'r', encoding='utf-8') as file:
            # le a primeira linha como cabeçalhos
            header_line = file.readline().rstrip('\n')
            if not header_line.strip():
                print("Arquivo vazio ou primeira linha vazia")
                return

            # faz o parse dos cabeçalhos usando o delimitador
            headers = [field.strip() for field in header_line.split(delimiter)]
            
            # le as linhas de dados (começando em 2, pois a primeira linha é o cabeçalho)
            for line_number, line in enumerate(file, start=2):
                raw_line = line.rstrip('\n')
                if not raw_line.strip():
                    continue
                # faz o parse dos campos usando o delimitador
                fields = [field.strip() for field in raw_line.split(delimiter)]
                print(f'Registro {line_number-1:02d}:')
                # usa os nomes reais dos campos
                for header, field in zip(headers, fields):
                    print(f'  {header}: {field}')
                print()
    except FileNotFoundError: 
        print(f'O arquivo não foi encontrado: {filepath}')

# Desafio 2
def search_by_id(filepath, search_id, delimiter=';'):
    try:
        with open(filepath, 'r', encoding='utf-8') as file:
            # le a primeira linha como cabeçalhos e faz o parse dos cabeçalhos usando o delimitador
            header_line = file.readline().rstrip('\n')
            headers = [field.strip() for field in header_line.split(delimiter)]

            for line in file:
                raw_line = line.rstrip('\n')
                if not raw_line.strip():
                    continue
                # faz o parse de acordo com o delimiter
                fields = [field.strip() for field in raw_line.split(delimiter)]
                if fields[0] == search_id:  # assume ID está na primeira coluna
                    print(f'Registro encontrado:')
                    # depois de achar o ID, imprime o registro com o ID escolhido
                    for header, field in zip(headers, fields):
                        print(f'  {header}: {field}')
                    return
            print(f'Nenhum registro encontrado com ID: {search_id}')
    except FileNotFoundError:
        print(f'O arquivo não foi encontrado: {filepath}')
  
# Desafio 3
def filter_by_field(filepath, field_name, field_value, delimiter=';'):
    try:
        with open(filepath, 'r', encoding='utf-8') as file:
            # le a primeira linha como cabeçalhos e faz o parse dos cabeçalhos usando o delimitador
            header_line = file.readline().rstrip('\n')
            headers = [field.strip() for field in header_line.split(delimiter)]

            # verifica se o campo existe nos cabeçalhos
            if field_name not in headers:
                print(f'Campo "{field_name}" não encontrado nos cabeçalhos.')
                return

            # encontra o índice do campo para filtrar
            field_index = headers.index(field_name)
            found = False

            # percorre as linhas do arquivo e filtra os registros pelo campo e valor especificados
            for line in file:
                raw_line = line.rstrip('\n')
                if not raw_line.strip():
                    continue
                fields = [field.strip() for field in raw_line.split(delimiter)]
                if fields[field_index] == field_value:
                    print(f'Registro encontrado:')
                    for header, field in zip(headers, fields):
                        print(f'  {header}: {field}')
                    found = True
            
            if not found:
                print(f'Nenhum registro encontrado com {field_name} = {field_value}')
    except FileNotFoundError:
        print(f'O arquivo não foi encontrado: {filepath}')

# main
def menu():
    while True:
        print("\n===MENU===")
        print("1. Exibir todos os registros")
        print("2. Buscar voo por ID")
        print("3. Filtrar registros por campo")
        print("4. Sair")

        choice = input("Escolha uma opção (1-4): ")

        if choice == '1':
            print("\n=== Todos os Registros ===")
            parse_txt_file('Aula 03 - Voos do Aeroporto.txt', delimiter=';')
        elif choice == '2':
            print("\n=== Buscar Voo por ID ===")
            search_id = input("Digite o ID do voo a ser buscado: ")
            search_by_id('Aula 03 - Voos do Aeroporto.txt', search_id, delimiter=';')
        elif choice == '3':
            print("\n=== Filtrar Registros por Campo ===")
            field_name = input("Digite o nome do campo a ser filtrado: ")
            field_value = input("Digite o valor do campo a ser filtrado: ")
            filter_by_field('Aula 03 - Voos do Aeroporto.txt', field_name, field_value, delimiter=';')
        elif choice == '4':
            print("\nSaindo do programa.")
            break
        else:
            print("\nOpção inválida. Tente novamente.")

if __name__ == "__main__":
    menu()
