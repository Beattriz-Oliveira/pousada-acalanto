import re
import os
from data_entry import conectar
from datetime import datetime

def limpar_padronizar_telefone (tel):
    
    # Tratamento de telefones vazios
    if not tel:
        return None
    
    # Remoção de caracteres que não sejam numeros
    numeros = ''.join(filter(str.isdigit,tel))
    
    # Padronização
    if len(numeros) >= 12 and numeros.startswith('55'):
        numeros = numeros[2:]
    if numeros.startswith('0'):
        numeros = numeros[1:]
        
    if len(numeros) == 10:
        numeros = numeros[:2] + '9' + numeros[2:]
        
    if len(numeros) < 11:
        return None
    
    return numeros

def registrar_log (cursor, etapa, registros, status='OK', mensagem=None):
    cursor.execute(
        'INSERT INTO etl_log(etapa, executado_em, status, mensagem, registro) VALUES (%s, %s, %s, %s, %s)',
        (etapa, datetime.now(),status, mensagem, registros)
    )

def etl_telefone(cursor):
    cursor.execute(
        'SELECT id_cliente, telefone FROM cliente'
    )
    clientes = cursor.fetchall()
    
    atualizados = 0
    invalidos = 0
    
    for id_cliente, tel_original in clientes:
        tel_limpo = limpar_padronizar_telefone(tel_original)
    
        if tel_limpo is None:
            invalidos += 1
            continue
        
        cursor.execute(
            'UPDATE cliente SET telefone = %s WHERE id_cliente = %s',
            (tel_limpo, id_cliente)
        )
        atualizados += 1
        
    return atualizados, invalidos

def main():
    db = None
    cursor = None
    
    try:
        db = conectar()
        cursor = db.cursor()
        
        print ("Iniciando ETL...")
        
        atualizados, invalidos = etl_telefone(cursor)
        registrar_log(
            cursor,
            etapa= "Padronizacao telefone",
            registros= atualizados,
            status= "Ok",
            mensagem= f'{atualizados} atualizados, {invalidos} invalidos ignorados.'
        )
        
        db.commit()
        print(f'✔ ETL concluído! {atualizados} telefones atualizados, {invalidos} ignorados.')

    except Exception as e:
        print(f'ERRO no ETL: {e}')
        if db:
            db.rollback()
        if cursor:
            registrar_log(cursor, 'Padronizacao telefone', 0, 'ERRO', str(e))
            db.commit()

    finally:
        if cursor: cursor.close()
        if db and db.is_connected(): db.close()

if __name__ == '__main__':
    main()