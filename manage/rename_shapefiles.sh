#!/bin/bash

# Verifica se todos os argumentos foram fornecidos
if [ "$#" -ne 2 ]; then
  echo "Erro: Número incorreto de argumentos."
  echo "Uso correto: $0 <diretorio> <novo_nome_base>"
  echo "Exemplo: $0 /home/lucas/documentos a_br_assentamentos_brasil"
  exit 1
fi

# Atribui os parâmetros passados na linha de comando às variáveis
DIRECTORY=$1  # Diretório que contém os arquivos
NEW_NAME=$2   # Novo nome base para os arquivos

# Verifica se o diretório existe
if [ ! -d "$DIRECTORY" ]; then
  echo "Erro: O diretório $DIRECTORY não existe."
  exit 1
fi

# Loop através de todos os arquivos no diretório
for file in "$DIRECTORY"/*; do
  # Verifica se é um arquivo
  if [ -f "$file" ]; then
    # Extrai a extensão do arquivo
    extension="${file##*.}"
    
    # Define o novo nome com o nome base e extensão
    new_filename="$NEW_NAME.$extension"
    
    # Renomeia o arquivo
    mv "$file" "$DIRECTORY/$new_filename"
    
    echo "Arquivo renomeado para: $new_filename"
  fi
done

echo "Renomeação completa!"

