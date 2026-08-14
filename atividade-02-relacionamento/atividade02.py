ARQUIVO_ALUNOS = "alunos.txt"
ARQUIVO_NOTAS = "notas.txt"

# 1
def cadastrar_aluno():
    print("\n--- CADASTRAR ALUNO ---")

    id_aluno = input("ID: ")
    nome = input("Nome: ")
    telefone = input("Telefone: ")
    email = input("E-mail: ")

    with open(ARQUIVO_ALUNOS, "a", encoding="utf-8") as arquivo:
        arquivo.write(
            f"{id_aluno};{nome};{telefone};{email}\n"
        )
    print("Aluno cadastrado com sucesso!")

# 2
def listar_alunos():
    print("\n--- LISTA DE ALUNOS ---")
    try:
        with open(ARQUIVO_ALUNOS, "r", encoding="utf-8") as arquivo:
            for linha in arquivo:
                dados = linha.strip().split(";")

                print(f"ID: {dados[0]}")
                print(f"Nome: {dados[1]}")
                print(f"Telefone: {dados[2]}")
                print(f"E-mail: {dados[3]}")
                print("-" * 30)
    except FileNotFoundError:
        print("Nenhum aluno cadastrado.")

# BUSCA
def buscar_aluno_por_nome(nome_busca):
    try:
        with open(ARQUIVO_ALUNOS, "r", encoding="utf-8") as arquivo:

            for linha in arquivo:
                dados = linha.strip().split(";")

                id_aluno = dados[0]
                nome = dados[1]

                if nome.lower() == nome_busca.lower():
                    return id_aluno, nome
    except FileNotFoundError:
        return None
    return None

# 3
def cadastrar_nota():
    print("\n--- CADASTRAR NOTA ---")

    nome_aluno = input("Nome do aluno: ")

    aluno = buscar_aluno_por_nome(nome_aluno)

    if aluno is None:
        print("Aluno não encontrado.")
        return

    id_aluno = aluno[0]

    disciplina = input("Disciplina: ")
    nota = input("Nota: ")

    with open(ARQUIVO_NOTAS, "a", encoding="utf-8") as arquivo:
        arquivo.write(
            f"{id_aluno};{disciplina};{nota}\n"
        )
    print("Nota cadastrada com sucesso!")

# 4
def consultar_nota():
    print("\n--- CONSULTAR NOTA ---")

    nome_aluno = input("Nome do aluno: ")
    disciplina_busca = input("Disciplina: ")

    try:
        aluno = buscar_aluno_por_nome(nome_aluno)

        if aluno is None:
            print("Aluno não encontrado.")
            return

        id_aluno = aluno[0]
        nota_encontrada = False

        with open(ARQUIVO_NOTAS, "r", encoding="utf-8") as arquivo:
            for linha in arquivo:
                dados = linha.strip().split(";")

                if len(dados) < 3:
                    continue  # Ignora linhas mal formatadas

                id_nota = dados[0]
                disciplina = dados[1]
                nota = dados[2]

                if id_nota == id_aluno and disciplina.lower() == disciplina_busca.lower():
                    print(f"Nota encontrada: {nota}")
                    nota_encontrada = True
                    break

        if not nota_encontrada:
            print(f"Nenhuma nota encontrada para o aluno '{nome_aluno}' na disciplina '{disciplina_busca}'.")
    except FileNotFoundError:
        print("Nenhuma nota cadastrada.")       

# 5
def listar_notas_aluno():
    print("\n--- LISTAR NOTAS DO ALUNO ---")

    try:
        nome_aluno = input("Nome do aluno: ")
        aluno = buscar_aluno_por_nome(nome_aluno)

        if aluno is None:
            print("Aluno não encontrado.")
            return

        id_aluno = aluno[0]
        notas_encontradas = []

        with open(ARQUIVO_NOTAS, "r", encoding="utf-8") as arquivo:
            for linha in arquivo:
                dados = linha.strip().split(";")

                if len(dados) < 3:
                    continue  # Ignora linhas mal formatadas

                id_nota = dados[0]
                disciplina = dados[1]
                nota = dados[2]

                if id_nota == id_aluno:
                    notas_encontradas.append((disciplina, nota))

        if notas_encontradas:
            print(f"Notas do aluno '{nome_aluno}':")
            for disciplina, nota in notas_encontradas:
                print(f"Disciplina: {disciplina}, Nota: {nota}")
        else:
            print(f"Nenhuma nota encontrada para o aluno '{nome_aluno}'.")

    except FileNotFoundError:
        print("Nenhuma nota cadastrada.")

# 6
def calcular_media():
    print("\n--- CALCULAR MÉDIA ---")
    
    try:
        nome_aluno = input("Nome do aluno: ")
        aluno = buscar_aluno_por_nome(nome_aluno)

        if aluno is None:
            print("Aluno não encontrado.")
            return

        id_aluno = aluno[0]
        notas = []

        with open(ARQUIVO_NOTAS, "r", encoding="utf-8") as arquivo:
            for linha in arquivo:
                dados = linha.strip().split(";")

                if len(dados) < 3:
                    continue  # Ignora linhas mal formatadas

                id_nota = dados[0]
                nota = dados[2]

                if id_nota == id_aluno:
                    try:
                        notas.append(float(nota))
                    except ValueError:
                        print(f"Nota inválida encontrada: {nota}. Ignorando.")

        if notas:
            media = sum(notas) / len(notas)
            print(f"Média do aluno '{nome_aluno}': {media:.2f}")
        else:
            print(f"Nenhuma nota encontrada para o aluno '{nome_aluno}'.")

    except FileNotFoundError:
        print("Nenhuma nota cadastrada.")

# MENU
def menu():
    while True:
        print("\n==============================")
        print(" SISTEMA ACADÊMICO")
        print("==============================")
        print("1 - Cadastrar aluno")
        print("2 - Listar alunos")
        print("3 - Cadastrar nota")
        print("4 - Consultar nota")
        print("5 - Listar notas de um aluno")
        print("6 - Calcular média")
        print("0 - Sair")

        opcao = input("\nEscolha uma opção: ")

        if opcao == "1":
            cadastrar_aluno()
        elif opcao == "2":
            listar_alunos()
        elif opcao == "3":
            cadastrar_nota()
        elif opcao == "4":
            consultar_nota()
        elif opcao == "5":
            listar_notas_aluno()
        elif opcao == "6":
            calcular_media()
        elif opcao == "0":
            print("Sistema encerrado.")
            break
        else:
            print("Opção inválida!")

if __name__ == "__main__":
    menu()