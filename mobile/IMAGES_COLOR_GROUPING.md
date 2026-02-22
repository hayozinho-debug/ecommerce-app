# Sistema de Agrupamento de Imagens por Cor

## Visão Geral

O sistema de agrupamento de imagens por cor permite que produtos com múltiplas variantes (tamanhos e cores diferentes) exibam automaticamente todas as fotos relacionadas a uma cor específica, independente do tamanho/SKU.

## Como Funciona

### Exemplo Prático

Para um produto com os seguintes SKUs:
- **194892-2** (Cor: Azul, Tamanho: M) → Foto A
- **194892-3** (Cor: Azul, Tamanho: G) → Foto B  
- **194892-4** (Cor: Azul, Tamanho: GG) → Foto C

Quando o usuário seleciona a cor **Azul**, o sistema exibe **TODAS** as fotos (A, B e C) juntas, pois pertencem ao mesmo grupo de cor.

## Implementação Técnica

### 1. Agrupamento de Imagens (`_getAvailableImages()`)

O método coleta imagens de duas fontes:

#### Fonte 1: Imagens de Variantes
```dart
// Busca todas as variantes com a cor selecionada
final variantsOfColor = widget.product.variants!.where((v) => 
  v.color != null && v.color == _selectedColor
).toList();

// Coleta as imagens dessas variantes
for (var variant in variantsOfColor) {
  if (variant.image != null && variant.image!.isNotEmpty) {
    // Adiciona à lista de imagens da cor
  }
}
```

**Como funciona:**
- Procura TODAS as variantes que têm a mesma cor (ex: todas as variantes "Azul")
- Coleta a imagem de cada variante
- Agrupa todas as imagens desse grupo de cor

#### Fonte 2: Imagens Principais com AltText
```dart
// Busca imagens do produto principal que correspondem à cor pelo altText
final filteredImages = widget.product.images.where((img) {
  if (img.altText == null || img.altText!.isEmpty) return false;
  return _matchesColor(img.altText!, _selectedColor!);
}).toList();
```

**Como funciona:**
- Verifica as imagens principais do produto
- Usa o campo `altText` para identificar a cor (ex: "Cor_Azul")
- Adiciona imagens que correspondem à cor selecionada

#### Sistema de Prevenção de Duplicatas
```dart
final seenUrls = <String>{}; // Set para tracking

// Ao adicionar cada imagem
if (!seenUrls.contains(img.url)) {
  seenUrls.add(img.url);
  colorImages.add(img);
}
```

### 2. Seleção de Cor Representativa (`_getAvailableColors()`)

Para exibir a miniatura de cada cor:

```dart
// Busca a primeira imagem disponível para essa cor
String? colorImage = variant.image;

// Se a variante atual não tem imagem, busca em outras variantes da mesma cor
if (colorImage == null || colorImage.isEmpty) {
  final variantsOfSameColor = widget.product.variants!.where((v) => 
    v.color == variant.color && v.image != null && v.image!.isNotEmpty
  );
  if (variantsOfSameColor.isNotEmpty) {
    colorImage = variantsOfSameColor.first.image;
  }
}

// Fallback: procura nas imagens principais
if (colorImage == null || colorImage.isEmpty) {
  final matchingImage = widget.product.images.firstWhere(
    (img) => img.altText != null && _matchesColor(img.altText!, variant.color!),
    orElse: () => widget.product.images.first,
  );
  colorImage = matchingImage.url;
}
```

**Estratégia de busca (em ordem):**
1. Imagem da própria variante
2. Imagem de outra variante da mesma cor
3. Imagem principal com altText correspondente
4. Primeira imagem do produto (fallback)

## Sistema de Matching de Cores

O método `_matchesColor()` identifica se uma imagem pertence a uma cor:

### Estratégias de Matching

1. **Formato Padrão:** `Cor_NomeDaCor`
2. **Match sem Espaços:** Remove espaços e compara
3. **Tokens Individuais:** Para cores compostas (ex: "Azul Marinho")
4. **Normalização:** Remove acentos e pontuação

### Exemplos de Match

| Cor Selecionada | AltText que Corresponde |
|----------------|------------------------|
| Azul | `Cor_Azul`, `cor_azul`, `Azul` |
| Azul Marinho | `Cor_Azul_Marinho`, `azul marinho` |
| Preto | `Cor_Preto`, `preto`, `PRETO` |

## Fluxo de Uso

1. **Usuário acessa detalhes do produto**
   - Sistema carrega todas as variantes
   - Identifica cores disponíveis

2. **Usuário seleciona uma cor**
   - `_getAvailableImages()` é chamado
   - Sistema busca todas as imagens daquela cor
   - Agrupa imagens de todos os SKUs da mesma cor
   - Exibe o carrossel com todas as fotos do grupo

3. **Navegação entre imagens**
   - Usuário pode deslizar para ver todas as fotos da cor
   - Imagens são de diferentes variantes/tamanhos, mas mesma cor

## Benefícios

✅ **Experiência Unificada:** Usuário vê todas as fotos de uma cor, não apenas de um tamanho  
✅ **Sem Duplicatas:** Sistema previne imagens repetidas  
✅ **Flexível:** Funciona com imagens de variantes E imagens principais  
✅ **Robusto:** Múltiplas estratégias de matching e fallbacks  

## Estrutura de Dados

### ProductVariant
```dart
class ProductVariant {
  final String sku;      // Ex: "194892-2"
  final String? size;    // Ex: "M", "G", "GG"
  final String? color;   // Ex: "Azul", "Preto"
  final String? image;   // URL da imagem específica da variante
  // ...
}
```

### ProductImage
```dart
class ProductImage {
  final String url;      // URL da imagem
  final String? altText; // Ex: "Cor_Azul", usado para matching
}
```

## Manutenção

### Para adicionar novos produtos:

1. **Configure as variantes** com cor e tamanho corretos
2. **Associe imagens** a cada variante (campo `image`)
3. **Configure altText** nas imagens principais (formato: `Cor_NomeDaCor`)

### Troubleshooting:

**Problema:** Imagens não aparecem ao selecionar cor
- Verifique se as variantes têm o campo `color` preenchido
- Confirme que `variant.image` tem URL válida OU
- Confirme que imagens principais têm `altText` com formato correto

**Problema:** Imagens duplicadas
- O sistema já previne, mas verifique se as URLs são exatamente iguais
- Normalize URLs antes de adicionar ao produto
