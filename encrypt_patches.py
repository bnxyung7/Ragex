#!/usr/bin/env python3
"""
Script para encriptar archivos .3105 usando AES-256-GCM
Compatible con FileEncryptionService.swift de iOS
"""

import os
import sys
import hashlib
from pathlib import Path
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC

# Configuración (debe coincidir con FileEncryptionService.swift)
SALT = "RagexV2Secure2024"
MASTER_KEY = "RagexMasterEncryption2024"  # Key maestra para encriptar archivos en build

class PatchEncryptor:
    def __init__(self, user_key: str = MASTER_KEY):
        """Inicializa el encriptador con la key del usuario"""
        self.user_key = user_key
        self.encryption_key = self._derive_key(user_key)
        self.aesgcm = AESGCM(self.encryption_key)
        
    def _derive_key(self, user_key: str) -> bytes:
        """
        Deriva una key de 256 bits usando SHA256
        Debe coincidir EXACTAMENTE con FileEncryptionService.swift
        """
        # Combinar user key + salt (igual que Swift)
        key_material = (user_key + SALT).encode('utf-8')
        
        # SHA256 hash (igual que Swift)
        key_hash = hashlib.sha256(key_material).digest()
        
        return key_hash
    
    def encrypt_file(self, input_path: Path, output_path: Path = None) -> bool:
        """
        Encripta un archivo .3105 a .3105e
        
        Args:
            input_path: Ruta del archivo original
            output_path: Ruta del archivo encriptado (opcional)
            
        Returns:
            True si tuvo éxito
        """
        try:
            # Leer archivo original
            with open(input_path, 'rb') as f:
                plaintext = f.read()
            
            # Generar nonce aleatorio de 12 bytes (estándar AES-GCM)
            nonce = os.urandom(12)
            
            # Encriptar con AES-GCM
            ciphertext = self.aesgcm.encrypt(nonce, plaintext, None)
            
            # Combinar nonce + ciphertext (formato compatible con Swift SealedBox.combined)
            combined = nonce + ciphertext
            
            # Determinar ruta de salida
            if output_path is None:
                output_path = input_path.with_suffix('.3105e')
            
            # Escribir archivo encriptado
            with open(output_path, 'wb') as f:
                f.write(combined)
            
            print(f"✅ Encriptado: {input_path.name} → {output_path.name}")
            return True
            
        except Exception as e:
            print(f"❌ Error encriptando {input_path.name}: {e}")
            return False
    
    def decrypt_file(self, input_path: Path) -> bytes:
        """
        Desencripta un archivo .3105e (para verificación)
        
        Args:
            input_path: Ruta del archivo encriptado
            
        Returns:
            Datos desencriptados
        """
        try:
            # Leer archivo encriptado
            with open(input_path, 'rb') as f:
                combined = f.read()
            
            # Separar nonce (primeros 12 bytes) y ciphertext
            nonce = combined[:12]
            ciphertext = combined[12:]
            
            # Desencriptar
            plaintext = self.aesgcm.decrypt(nonce, ciphertext, None)
            
            print(f"✅ Desencriptado: {input_path.name}")
            return plaintext
            
        except Exception as e:
            print(f"❌ Error desencriptando {input_path.name}: {e}")
            raise
    
    def encrypt_directory(self, directory: Path, recursive: bool = True, delete_original: bool = False):
        """
        Encripta todos los archivos .3105 en un directorio
        
        Args:
            directory: Directorio a procesar
            recursive: Buscar en subdirectorios
            delete_original: Eliminar archivos originales después de encriptar
        """
        pattern = '**/*.3105' if recursive else '*.3105'
        files = list(directory.glob(pattern))
        
        if not files:
            print(f"⚠️  No se encontraron archivos .3105 en {directory}")
            return
        
        print(f"\n🔒 Encriptando {len(files)} archivos en {directory.name}...\n")
        
        encrypted_count = 0
        for file_path in files:
            # Saltar si ya existe el archivo encriptado
            encrypted_path = file_path.with_suffix('.3105e')
            if encrypted_path.exists():
                print(f"⏭️  Ya existe: {encrypted_path.name}")
                continue
            
            if self.encrypt_file(file_path):
                encrypted_count += 1
                
                # Eliminar original si se solicita
                if delete_original:
                    file_path.unlink()
                    print(f"   🗑️  Eliminado original: {file_path.name}")
        
        print(f"\n✅ Encriptados: {encrypted_count}/{len(files)} archivos")
        
        if delete_original and encrypted_count > 0:
            print(f"🗑️  Eliminados {encrypted_count} archivos originales")


def main():
    """Función principal del script"""
    print("=" * 70)
    print("🔐 RAGEX PATCH ENCRYPTION TOOL")
    print("=" * 70)
    
    # Ruta base del proyecto
    base_path = Path(__file__).parent / "ThreeOneOSFive" / "PreinstalledPatches"
    
    if not base_path.exists():
        print(f"❌ Error: No se encuentra la carpeta {base_path}")
        sys.exit(1)
    
    print(f"\n📁 Directorio base: {base_path}\n")
    
    # Confirmar con usuario
    print("⚠️  ADVERTENCIA: Este proceso encriptará TODOS los archivos .3105")
    print("   Los archivos originales se MANTENDRÁN a menos que uses --delete\n")
    
    # Verificar argumentos
    delete_original = "--delete" in sys.argv
    if delete_original:
        print("🗑️  MODO: Eliminar archivos originales después de encriptar\n")
    
    response = input("¿Continuar? (s/N): ").strip().lower()
    if response not in ['s', 'si', 'yes', 'y']:
        print("❌ Cancelado por el usuario")
        sys.exit(0)
    
    # Inicializar encriptador
    encryptor = PatchEncryptor()
    
    # Encriptar FREE_FIRE
    free_fire_path = base_path / "FREE_FIRE"
    if free_fire_path.exists():
        print("\n" + "=" * 70)
        print("🎮 FREE FIRE")
        print("=" * 70)
        encryptor.encrypt_directory(free_fire_path, recursive=True, delete_original=delete_original)
    
    # Encriptar FREE_FIRE_MAX
    free_fire_max_path = base_path / "FREE_FIRE_MAX"
    if free_fire_max_path.exists():
        print("\n" + "=" * 70)
        print("🎮 FREE FIRE MAX")
        print("=" * 70)
        encryptor.encrypt_directory(free_fire_max_path, recursive=True, delete_original=delete_original)
    
    print("\n" + "=" * 70)
    print("✅ PROCESO COMPLETADO")
    print("=" * 70)
    print("\n💡 Los archivos .3105e están listos para compilar en el IPA")
    print("💡 El IPA desencriptará automáticamente con la key del usuario\n")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n❌ Proceso interrumpido por el usuario")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Error fatal: {e}")
        sys.exit(1)
