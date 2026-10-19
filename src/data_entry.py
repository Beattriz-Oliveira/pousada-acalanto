from faker import Faker
import mysql.connector
import random
from datetime import timedelta, date
from dotenv import load_dotenv
import os

# Carregando as variáveis do .env
load_dotenv()

fk = Faker('pt_BR')

# Conectando no database
def conectar():
    return mysql.connector.connect(
        host = os.getenv('db_host'),
        user = os.getenv('db_user'),
        password = os.getenv('db_pass'),
        database = os.getenv('db_name')
    )

def inserir_tipos_quarto (cursor):
    tipos = [
        ("individual",150.00,2),
        ("duplo", 250.00, 2),
        ("familiar", 400.00, 4),
        ("luxo", 600.00, 4)
        ]
    
    # Verifica se os tipos quartos já existem
    cursor.execute('SELECT COUNT(*) FROM tipo_quarto')
    if cursor.fetchone()[0] > 0:
        print ("tipo_quarto: já exite, pulando ...")
        return
    for desc, preco,cap in tipos:
        cursor.execute(
            'INSERT INTO tipo_quarto(descricao,valor_diaria,capacidade_max) VALUES (%s,%s,%s)', 
            (desc,preco,cap)
        )
    print ("✔ tipo_quarto inserido com sucesso! 4 tipos registrados.")
        
def inserir_quartos (cursor):
    # Verifica se os quartos já existem
    cursor.execute('SELECT COUNT(*) FROM quarto')
    if cursor.fetchone()[0] >= 20:
        print ("quartos: já exite, pulando ...")
        return
        
    # Coleta o id do tipo_quarto
    cursor.execute('SELECT id_tipo FROM tipo_quarto')
    tipos = [t[0] for t in cursor.fetchall()]
    
    situacoes = ["disponivel", "ocupado", "em limpeza"]
    
    for i in range (1,21):
        num_quarto = f'Q{i}'
        situacao = random.choice(situacoes)
        id_tipo = random.choice(tipos)
        cursor.execute(
            'INSERT INTO quarto(id_tipo, num_quarto, situacao) VALUES (%s, %s, %s)',
            (id_tipo,num_quarto,situacao)
        )
    print ("✔ quarto inserido com sucesso! 20 quartos registrados.")
        
def inserir_cliente (cursor, quantidade = 600):
    ufs = ['AC', 'AL', 'AP','AM', 'BA','CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO']
    inseridos = 0
    tentativas =  0
    
    while inseridos < quantidade and tentativas < quantidade * 3:
        tentativas += 1
        cpf = fk.cpf().replace('.', '').replace('-', '')
        email = fk.email()
        
         # Verifica duplicidade de CPF e email antes de inserir
        cursor.execute(
            'SELECT 1 FROM cliente WHERE cpf = %s OR email = %s',
            (cpf, email)
        )
        if cursor.fetchone():
            continue
        
        cursor.execute(
            'INSERT INTO cliente(nome, sobrenome, cpf, telefone, email, cidade, estado, dt_cadastro) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)',
            (fk.first_name(), fk.last_name(), cpf, fk.phone_number(), email, fk.city(), random.choice(ufs), fk.date_between(start_date = '-4y', end_date = 'today'))
        )
        inseridos += 1
        
    print(f'  clientes: {inseridos} inseridos.')
    
def inserir_catalogo (cursor):
    catalogo = {
        'Alimentos': {
            'Lanche Rapido': ['Batata chips', 'Amendoim', 'Mix de sementes'],
            'Doces': ['Chocolate', 'Bombom', 'Bala de goma'],
            'Pratos Rapidos':['Cup noodles', 'Biscoito', 'Cookies']
        },
        'Bebidas': {
            'Nao Alcoolicas': ['Agua mineral', 'Agua de coco', 'Refrigerante', 'Suco'],
            'Bebidas Quentes':['Cafe', 'Cha'],
            'Alcoolicas': ['Cerveja', 'Vinho', 'Espumante']
        },
        'Higiene': {
            'Higiene Bucal': ['Escova de dente', 'Fio dental', 'Pasta de dente'],
            'Higiene Corporal':['Shampoo', 'Condicionador', 'Desodorante', 'Protetor solar'],
            'Bem Estar': ['Absorvente', 'Band-aid', 'Lenco umedecido']
        },
        'Roupas': {
            'Camisas': ['Manga longa', 'Regata', 'Manga curta', 'Moletom'],
            'Calcas': ['Jeans', 'Cargo', 'Legging', 'Bermuda'],
            'Calcados': ['Tenis', 'Chinela', 'Sapatilha', 'Bota'],
            'Acessorios': ['Oculos de sol', 'Chapeu', 'Relogio', 'Sombrinha']
        },
        'Brinquedos': {
            'Bolas': ['Bola de futebol', 'Bola de basquete', 'Bola inflavel'],
            'Jogos': ['Quebra cabeca', 'Baralho', 'Dominó', 'Jogo de tabuleiro']
        }
    }
    
    for cat_nome, subcategorias in catalogo.items():
        
        # Insere a categoria, caso ela não exista
        cursor.execute(
            'INSERT IGNORE INTO categoria(nome_categoria) VALUES (%s)',
            (cat_nome,)
        )
        cursor.execute(
            'SELECT id_categoria FROM categoria WHERE nome_categoria = %s',
            (cat_nome,)
        )
        
        id_cat = cursor.fetchone()[0] 
        for sub_nome, produtos in subcategorias.items():
            
            # Insere a subcategoria, caso ela não exista
            cursor.execute(
                'SELECT 1 FROM subcategoria WHERE id_categoria = %s AND nome_subcategoria = %s',
                (id_cat,sub_nome)
            )
            if not cursor.fetchone():
                cursor.execute(
                    'INSERT INTO subcategoria(id_categoria, nome_subcategoria) VALUES (%s, %s)',
                    (id_cat, sub_nome)
                )
            
            cursor.execute(
                'SELECT id_subcategoria FROM subcategoria WHERE nome_subcategoria = %s AND id_categoria = %s',
                (sub_nome,id_cat)
            )
            id_sub = cursor.fetchone()[0]
            
            for pro_nome in produtos:
                
                # Insere os produtos, caso eles não existam
                cursor.execute(
                    'SELECT 1 FROM produto WHERE id_subcategoria = %s AND nome_produto = %s',
                    (id_sub, pro_nome)
                )
                
                if not cursor.fetchone():
                    custo = round(random.uniform(3.0, 25.0), 2)
                    preco = round(custo * random.uniform(1.5, 3.0), 2)
                    
                    cursor.execute(
                        'INSERT INTO produto(id_categoria, id_subcategoria, nome_produto, estoque_atual, preco_unitario, valor_custo, ativo) VALUES (%s, %s, %s, %s, %s, %s, %s)',
                        (id_cat, id_sub, pro_nome, random.randint(10, 200), preco, custo, 1)
                    )
            
    print ("✔ catalogo inserido com sucesso! categoria, subcategoria e produto registrados.")
    
def inserir_reservas_hospedagem (cursor):
    
    # Retorna a lista dos ids necessários
    cursor.execute(
        'SELECT id_cliente FROM cliente'
    )
    clientes = [c[0] for c in cursor.fetchall()]
    
    cursor.execute(
        'SELECT id_quarto, id_tipo FROM quarto'
    )
    quartos = cursor.fetchall()
    
    cursor.execute(
        'SELECT id_tipo, valor_diaria FROM tipo_quarto'
    )
    precos = dict(cursor.fetchall())
    
    for id_cliente in random.sample(clientes, min(550, len(clientes))):
        id_quarto, id_tipo = random.choice(quartos)
        preco = precos[id_tipo]
        entrada = fk.date_between('-4y', 'today')
        saida = entrada + timedelta(days= random.randint(2,14))
        status_resv = random.choices(['confirmada','cancelada','concluida'], weights = [20, 10, 70]) [0]
        
        cursor.execute(
            'INSERT INTO reserva(id_cliente, id_quarto, dt_reserva, dt_entrada_prev, dt_saida_prev, status) VALUES (%s, %s, %s, %s, %s, %s)',
            (id_cliente, id_quarto, fk.date_between('-4y','-3y'), entrada, saida, status_resv)
        )
        
        id_reserva = cursor.lastrowid
        
        if status_resv == 'concluida':
            dias = (saida - entrada).days
            valor = round(dias * float(preco), 2)
            status_hosp = random.choices(['ativa','finalizada'], weights= [20,80])[0]
            
            cursor.execute(
                'INSERT INTO hospedagem(id_reserva, id_cliente, id_quarto, dt_checkin, dt_checkout, valor_total, status) VALUES (%s, %s, %s, %s, %s, %s, %s)',
                (id_reserva, id_cliente, id_quarto, entrada, saida,valor, status_hosp)
            )
    print ("✔ reserva e hospedagem inserido com sucesso!")
            
def inserir_vendas (cursor):
    
    cursor.execute(
        'SELECT id_cliente FROM cliente'
    )
    clientes = [c[0] for c in cursor.fetchall()]
    
    cursor.execute(
        'SELECT id_produto, preco_unitario, valor_custo FROM produto WHERE ativo = 1'
    )
    produtos = cursor.fetchall()
    
    formas_pag = ['dinheiro', 'pix', 'credito', 'debito']
    
    # Vendas
    for id_cliente in clientes:
        num_vendas = random.randint (1, 10)
        
        for _ in range(num_vendas):
            dt_venda = fk.date_between ('-4y', 'today')
            origem = random.choices(['hospede','externo'], weights= [30, 70])[0]
            
            # Cliente externo não possui id registrado
            id_cli_insert = id_cliente if origem == 'hospede' else None
            
            cursor.execute(
                'INSERT INTO venda(id_cliente, dt_venda, valor_total, origem) VALUES (%s, %s, %s, %s)',
                (id_cli_insert, dt_venda, 0.00, origem)
            )
            id_venda = cursor.lastrowid
    
            # Itens
            valor_total = 0.0
            itens_usados = set()
            num_itens = random.randint (1,11)
            
            for _ in range(num_itens):
                id_prod, preco, custo = random.choice(produtos)
                
                if id_prod in itens_usados:
                    continue
                itens_usados.add(id_prod)
                
                qtde = random.randint(1,8)
                
                cursor.execute(
                    'INSERT INTO itens_venda(id_venda, id_produto, quantidade, preco_unit_momento) VALUES (%s, %s, %s, %s)',
                    (id_venda, id_prod, qtde, preco)
                )
                valor_total += qtde * float(preco)
            
            # Atualiza o valor total
            cursor.execute(
                'UPDATE venda SET valor_total = %s WHERE id_venda = %s',
                (round(valor_total, 2),id_venda)
            )
            
            # Pagamento
            dt_max = min(dt_venda + timedelta(days=3), date.today())
            cursor.execute(
                'INSERT INTO pagamento(id_venda, forma_pagamento, dt_pagamento, valor) VALUES (%s, %s, %s, %s)',
                (id_venda, random.choice(formas_pag), fk.date_between(dt_venda, dt_max), round(valor_total,2))
            )
    
    print ("✔ vendas inserido com sucesso! venda, itens_venda e pagamento registrados.")
    
def main():
    bd     = None
    cursor = None

    try:
        bd     = conectar()
        cursor = bd.cursor()

        print('Iniciando carga de dados...')

        inserir_tipos_quarto(cursor)
        bd.commit()

        inserir_quartos(cursor)
        bd.commit()

        inserir_cliente(cursor, 600)
        bd.commit()

        inserir_catalogo(cursor)
        bd.commit()

        inserir_reservas_hospedagem(cursor)
        bd.commit()

        inserir_vendas(cursor)
        bd.commit()

        print('✔ Carga concluída com sucesso!')

    except mysql.connector.Error as e:
        print(f'ERRO MySQL: {e}')
        if bd:
            bd.rollback()

    finally:
        if cursor: cursor.close()
        if bd and bd.is_connected(): bd.close()


if __name__ == '__main__':
    main()