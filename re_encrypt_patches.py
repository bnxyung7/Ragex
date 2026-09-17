#!/usr/bin/env python3
"""
Script para RE-ENCRIPTAR archivos .3105e con la key correcta
"""

import os
import hashlib
from pathlib import Path
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

SALT = "RagexV2Secure2024"
MASTER_KEY = "RagexMasterEncryption2024"

def derive_key(user_key: str) -> bytes:
    """Deriva key usando SHA256"""
    key_material = (user_key + SALT).encode('utf-8')
    key_hash = hashlib.sha256(key_material).digest()
    return key_hash

def decrypt_file(input_path: Path, key: bytes) -> bytes:
    """Desencripta un archivo .3105e"""
    try:
        aesgcm = AESGCM(key)
        with open(input_path, 'rb') as f:
            combined = f.read()
        
        nonce = combined[:12]
        ciphertext = combined[12:]
        plaintext = aesgcm.decrypt(nonce, ciphertext, None)
        return plaintext
    except Exception as e:
        print(f"❌ Error desencriptando {input_path.name}: {e}")
        raise

def encrypt_file(data: bytes, output_path: Path, key: bytes) -> bool:
    """Encripta datos a .3105e"""
    try:
        aesgcm = AESGCM(key)
        nonce = os.urandom(12)
        ciphertext = aesgcm.encrypt(nonce, data, None)
        combined = nonce + ciphertext
        
        with open(output_path, 'wb') as f:
            f.write(combined)
        
        return True
    except Exception as e:
        print(f"❌ Error encriptando {output_path.name}: {e}")
        return False

def main():
    print("=" * 70)
    print("🔄 RE-ENCRIPTACIÓN DE ARCHIVOS .3105e")
    print("=" * 70)
    
    base_path = Path(__file__).parent / "ThreeOneOSFive" / "PreinstalledPatches"
    
    # Derivar key correcta
    correct_key = derive_key(MASTER_KEY)
    print(f"\n✅ Key derivada: {correct_key.hex()[:32]}...\n")
    
    # Buscar todos los .3105e
    files = list(base_path.glob("**/*.3105e"))
    
    if not files:
        print("❌ No se encontraron archivos .3105e")
        return
    
    print(f"📁 Encontrados {len(files)} archivos .3105e\n")
    
    print("⚠️ RE-ENCRIPTANDO AUTOMÁTICAMENTE...\n")
    
    success_count = 0
    fail_count = 0
    
    for file_path in files:
        try:
            print(f"🔄 Procesando: {file_path.name}")
            
            # Intentar desencriptar con key actual
            plaintext = decrypt_file(file_path, correct_key)
            print(f"   ✅ Desencriptado ({len(plaintext)} bytes)")
            
            # Crear backup temporal
            backup_path = file_path.with_suffix('.3105e.bak')
            file_path.rename(backup_path)
            
            # Re-encriptar con key correcta
            if encrypt_file(plaintext, file_path, correct_key):
                print(f"   ✅ Re-encriptado correctamente")
                # Eliminar backup
                backup_path.unlink()
                success_count += 1
            else:
                # Restaurar backup si falla
                backup_path.rename(file_path)
                fail_count += 1
                
        except Exception as e:
            print(f"   ❌ Error: {e}")
            fail_count += 1
    
    print("\n" + "=" * 70)
    print(f"✅ Exitosos: {success_count}/{len(files)}")
    if fail_count > 0:
        print(f"❌ Fallidos: {fail_count}")
    print("=" * 70)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n❌ Cancelado por usuario")
    except Exception as e:
        print(f"\n❌ Error fatal: {e}")
