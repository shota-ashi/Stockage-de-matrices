# Stockage de matrices

- **Membres du binôme :**
  - GUEYE Mame Cheikh (@shota-ashi)
  - GUINARD Samuel ARMEL (@EcoreEtToujoursMoi)
- **Date de remise :** 1er novembre 2026

---

## Table des matières

- [1. Introduction](#1-introduction)
- [2. Conception](#2-conception)
  - [2.1. Organisation des modules](#21-organisation-des-modules)
  - [2.2. Graphe des inclusions et gardes `#ifndef`](#22-graphe-des-inclusions-et-gardes-ifndef)
  - [2.3. Règles de propriété de la mémoire](#23-règles-de-propriété-de-la-mémoire)
  - [2.4. Choix d'implémentation et sécurité](#24-choix-dimplémentation-et-sécurité)
  - [2.5. Contenu du Makefile](#25-contenu-du-makefile)
- [3. Réalisation](#3-réalisation)
  - [3.1. Code commenté](#31-code-commenté)
  - [3.2. Réponses rédigées aux questions de réflexion et sorties du test](#32-réponses-rédigées-aux-questions-de-réflexion-et-sorties-du-test)
    - [Exercice 1 : Allocation et destruction](#exercice-1--allocation-et-destruction)
    - [Exercice 2 : Entrées-sorties](#exercice-2--entrées-sorties)
    - [Exercice 3 : Calcul matriciel](#exercice-3--calcul-matriciel)
    - [Exercice 4 : Démonstration complète](#exercice-4--démonstration-complète)
- [4. Critères de validation finaux](#4-critères-de-validation-finaux)
  - [4.1. Vérifications mémoire](#41-vérifications-mémoire)
  - [4.2. Démonstration finale](#42-démonstration-finale)
  - [4.3. Bilan et difficultés](#43-bilan-et-difficultés)
    - [Répartition du travail](#répartition-du-travail)
    - [Aides extérieures](#aides-extérieures)

---

## 1. Introduction

### Présentation et objectifs du projet

Ce projet consiste à concevoir et implémenter en C une bibliothèque modulaire permettant la création, la manipulation, l'écriture/lecture sur fichier texte et le calcul arithmétique (addition et multiplication) de matrices d'entiers de dimensions dynamiques.

Les objectifs pédagogiques du TD sont :

1. Séparer l'interface d'un module (fichier `.h`) de son implémentation (fichier `.c`) ;
2. Compiler séparément plusieurs modules puis les assembler par édition de liens ;
3. Représenter une matrice de taille variable en mémoire et l'allouer dynamiquement, y compris en cas d'échec partiel ;
4. Établir et respecter des règles de propriété de la mémoire (qui alloue, qui utilise, qui libère) pour éviter toute fuite ;
5. Lire et écrire des données dans un fichier texte en vérifiant chaque opération ;
6. Programmer l'addition et la multiplication de matrices en contrôlant les dimensions ;
7. Concevoir une gestion d'erreurs uniforme et la vérifier par des tests.

### État de réalisation à la remise

**L'ensemble des modules et fonctionnalités est 100 % opérationnel et validé** :

- **Exercices 1 à 3 :** Les suites de tests unitaires (`test_ex1`, `test_ex2`, `test_ex3`) valident 100 % des vérifications (bilans 16/16, 14/14 et 14/14).
- **Exercice 4 :** Le programme `demo_matrices` gère avec succès l'ensemble des 10 scénarios d'utilisation (calculs d'addition/multiplication, détection d'erreurs et relecture des fichiers générés). Les scénarios 2, 6 et 8, présentés en [section 4.2](#42-démonstration-finale), sont des exemples représentatifs parmi les 10 scénarios intégralement validés lors du projet.
- **Qualité du code :** Compilation sans aucun avertissement (_warning_) avec les drapeaux stricts `-std=c11 -Wall -Wextra -Wpedantic`. Les trois suites de tests unitaires (`test_ex1`, `test_ex2`, `test_ex3`) ainsi que le programme principal `demo_matrices` ont été passés sous `valgrind` : 0 fuite mémoire et 0 accès invalide (voir [section 4.1](#41-vérifications-mémoire)).

---

## 2. Conception

### 2.1. Organisation des modules

Le projet repose sur une découpe en quatre modules fonctionnels autonomes articulés autour du programme principal (`main.c`). Cette structure permet de séparer clairement les responsabilités (gestion mémoire, entrées/sorties, opérations mathématiques) pour garantir la lisibilité et la maintenabilité du code.

```text
                     +-------------------+
                     |      main.c       |
                     +---------+---------+
                               |
       +-----------------------+-----------------------+
       |                       |                       |
       v                       v                       v
+--------------+       +----------------+       +------------------+
|  matrice_io  |       | matrice_calcul |       |   matrice_alloc  |
+-------+------+       +--------+-------+       +--------+---------+
        |                       |                        |
        +-----------------------+------------------------+
                                |
                                v
                        +---------------+
                        |   matrice.h   |
                        +---------------+
```

### 2.2. Graphe des inclusions et gardes `#ifndef`

#### Chaîne des dépendances

```text
main.c
 ├── matrice_io.h     ──► matrice.h
 ├── matrice_calcul.h ──► matrice.h
 └── matrice_alloc.h  ──► matrice.h
```

Comme `main.c` fait appel à plusieurs modules qui incluent tous `matrice.h`, le préprocesseur risquerait de copier plusieurs fois les mêmes définitions dans le code final. Sans protection, cela provoquerait une erreur de redéfinition au moment de la compilation.

Pour éviter cela, chaque fichier d'en-tête est encadré par des gardes d'inclusion :

```c
#ifndef MATRICE_H
#define MATRICE_H
#endif
```

Ceci garantit que le contenu du fichier n'est évalué qu'une seule fois par le préprocesseur, quel que soit le nombre d'inclusions dans le projet.

### 2.3. Règles de propriété de la mémoire

Pour prévenir toute fuite de mémoire et éviter les erreurs courantes (pointeurs sauvages, double libération), nous avons appliqué les règles suivantes :

- **Règle 1** : toute fonction qui instancie une matrice transfère l'entière propriété de la zone mémoire à l'appelant. C'est à lui qu'il revient de planifier sa libération.
- **Règle 2** : les fonctions de traitement ou d'affichage prennent des pointeurs constants. Elles lisent les données sans jamais modifier ni libérer la mémoire reçue.
- **Règle 3** : tout bloc alloué doit impérativement être libéré via `mat_detruire` dès qu'il n'est plus nécessaire.

**En cas d'échec** : si une allocation échoue, la structure est réinitialisée dans un état neutre et sécurisé. Cela permet d'appeler `mat_detruire` sur la matrice sans risque de plantage.

### 2.4. Choix d'implémentation et sécurité

#### Utilisation du mot-clé `static`

Les fonctions auxiliaires internes ont été déclarées `static` car cela restreint leur portée au fichier source où elles sont définies.

#### Nettoyage lors d'un échec d'allocation partiel

L'allocation d'un tableau à deux dimensions se fait en deux étapes : d'abord le tableau de pointeurs de lignes, puis chaque ligne individuellement. Si la mémoire vient à manquer au milieu du processus, il faut libérer ce qui a déjà été alloué. Une boucle de nettoyage arrière désalloue proprement les lignes déjà réservées avant d'annuler le tableau principal :

```c
for (size_t k = 0; k < i; k++) {
    free(m->coef[k]);
}
free(m->coef);
m->coef = NULL;
```

#### Détection des dépassements de capacité (Overflow)

Avant d'effectuer la moindre opération arithmétique, nous comparons les valeurs aux limites définies dans `<limits.h>`. Si un risque d'overflow est détecté, le calcul est interrompu et un code d'erreur dédié est retourné.

### 2.5. Contenu du Makefile

Le `Makefile` est compatible avec Linux/WSL (`rm -f`) et Windows (`del`) pour la cible `clean` :

```makefile
CC = gcc
CFLAGS = -std=c11 -Wall -Wextra -Wpedantic -g

ifeq ($(OS),Windows_NT)
    CLEAN_CMD = -del /f /q *.o *.exe main demo_matrices test_ex1 test_ex2 test_ex3 2>NUL
else
    CLEAN_CMD = rm -f *.o *.exe main demo_matrices test_ex1 test_ex2 test_ex3
endif

.PHONY: all clean

all: demo_matrices

demo_matrices: main.c matrice.c matrice_alloc.c matrice_calcul.c matrice_io.c
	$(CC) $(CFLAGS) -o $@ $^

clean:
	$(CLEAN_CMD)
```

---

## 3. Réalisation

### 3.1. Code commenté

### 3.2. Réponses rédigées aux questions de réflexion et sorties du test

#### Exercice 1 : Allocation et destruction

[matrice.c](matrice.c) [matrice_alloc.c](matrice_alloc.c)

##### Q3.1 :

Le passage par pointeur (`Matrice *`) est indispensable pour modifier directement la variable de l'appelant. Cela permet de remettre son pointeur interne à `NULL` et ses dimensions à 0 après la libération.

Si on passait la structure par valeur, la fonction ne travaillerait que sur une copie locale. La mémoire dynamique sur le tas serait bien libérée, mais la variable d'origine conserverait l'ancienne adresse mémoire, ce qui exposerait l'appelant à des accès invalides.

##### Q3.2 :

Pour une matrice de $n \times p$ :

- **Nombre d'appels à `calloc` :** $n + 1$ (un premier appel pour le tableau de pointeurs de lignes, puis $n$ appels, un pour chaque ligne).
- **Nombre d'appels à `free` :** $n + 1$ (libération des $n$ lignes, puis du tableau de pointeurs).

Si la $k$-ième allocation échoue, `mat_allouer` doit annuler les opérations précédentes en effectuant **$k - 1$ libérations**.

##### Q3.3 :

Appeler deux fois de suite `mat_detruire(&a)` est sans danger, car le premier appel remet le pointeur de données à `NULL`. Lors du second appel, la fonction détecte le pointeur nul (ou exécute `free(NULL)`), ce qui n'a aucun effet en C.

En revanche, si on écrit `Matrice b = a;`, C réalise une copie superficielle : `a` et `b` partagent la même adresse mémoire pour leurs données. Détruire `a` libère la mémoire et met le pointeur de `a` à `NULL`, mais `b` pointe toujours vers la zone libérée. L'appel `mat_detruire(&b)` tente alors de libérer un bloc déjà restitué, ce qui déclenche un comportement indéfini.

##### Q3.4 : Initialisation systématique avec `MATRICE_VIDE`

Commencer par `*res = MATRICE_VIDE` garantit que la variable reçue est immédiatement dans un état valide et prévisible (pointeur à `NULL`, dimensions à 0). Si la fonction échoue ensuite (dimensions hors limites ou échec de `calloc`), la matrice de l'appelant reste propre au lieu de conserver des valeurs indéterminées.

##### Résultat test :

```text
gcc -std=c11 -Wall -Wextra -Wpedantic -g -DMAT_TEST_ALLOC test_ex1.c matrice.c matrice_alloc.c -o test_ex1
PS C:\Users\L\Desktop\INSA CVL\Semester 1\Programmation C\td_matrices> .\test_ex1
=== Exercice 1 : matrice.c ===
[OK]    (1.a) message pour MAT_ERR_DIMENSIONS
[OK]    (1.a) message pour MAT_ERR_DEPASSEMENT
[OK]    (1.b) une matrice 1 x 2 est valide
[OK]    (1.b) NULL n'est pas valide
[OK]    (1.b) MATRICE_VIDE n'est pas valide
[OK]    (1.b) une matrice de 0 ligne n'est pas valide
=== Exercice 1 : matrice_alloc.c ===
[OK]    (1.c) mat_allouer refuse 0 ligne
[OK]    (1.c) mat_allouer refuse -2 colonnes
[OK]    (1.c) mat_allouer refuse une dimension > MAT_DIM_MAX
[OK]    (1.e) mat_allouer(&m, 3, 4) renvoie MAT_OK
[OK]    (1.e) m a 3 lignes et 4 colonnes
[OK]    (1.d) tous les coefficients valent 0
[OK]    (1.f) apres mat_detruire, m est vide
[OK]    (1.f) un second mat_detruire est sans danger
[OK]    (1.f) mat_detruire(NULL) ne plante pas
=== Exercice 1 : echecs d'allocation simules ===
[OK]    (1.d) chaque echec renvoie MAT_ERR_ALLOCATION et laisse *res vide

Bilan : 16 / 16 verifications reussies.
Pensez a verifier l'absence de fuite : valgrind --leak-check=full ./test_ex1
PS C:\Users\L\Desktop\INSA CVL\Semester 1\Programmation C\td_matrices>
```

#### Exercice 2 : Entrées-sorties

[matrice_io.c](matrice_io.c)

##### Q4.1 :

Cela garantit que le résultat n'est transmis à `*res` que si toute la lecture réussit. La fonction respecte ainsi le principe d'atomicité : elle renvoie soit la matrice entièrement lue, soit une matrice vide.

##### Q4.2 :

Non. La fonction utilise `fscanf`, qui lit des mots séparés par des caractères de séparation, quels qu'ils soient (espace, tabulation, saut de ligne). Ce n'est pas gênant, car le nombre de lignes et de colonnes indique combien de coefficients doivent être lus. Le principe « tolérant en lecture, strict en écriture » est bien respecté : la sortie est prévisible, mais le programme accepte plusieurs présentations valides des données.

##### Q4.3 :

Il suffit d'écrire les deux matrices successivement dans le même fichier, avec deux appels à `mat_ecrire`, sans fermer le fichier entre les deux écritures.

##### Q4.4 :

`fflush` force l'écriture des données se trouvant dans le tampon du flux de sortie. Cela ne dispense pas l'appelant d'appeler `fclose`, car `fflush` n'a aucune action sur la fermeture du fichier : le flux reste ouvert et ses ressources ne sont pas libérées.

##### Résultat test :

```text
=== Exercice 2 : affichage (verification visuelle) ===
M (4 x 3) :
        1        2        3
        4        5        6
        7        8        9
       10       11       12
(2.a) Vous devez voir ci-dessus 4 lignes : 1 2 3 / 4 5 6 / 7 8 9 / 10 11 12
=== Exercice 2 : ecriture ===
[OK]    ouverture de test_ex2_sortie.txt en ecriture
[OK]    (2.b) mat_ecrire renvoie MAT_OK
[OK]    (2.b) le fichier contient exactement le format attendu
[OK]    (2.b) mat_ecrire refuse une matrice vide
=== Exercice 2 : relecture ===
[OK]    (2.f) mat_lire relit le fichier : MAT_OK
[OK]    (2.e) la matrice relue est identique
[OK]    (2.e) espaces et sauts de ligne en trop sont toleres
=== Exercice 2 : fichiers incorrects ===
[OK]    (2.c) fichier vide
[OK]    (2.c) dimension nulle
[OK]    (2.c) dimension negative
[OK]    (2.e) coefficient manquant
[OK]    (2.e) donnee non numerique
[OK]    (2.e) entier trop grand pour un int
=== Exercice 2 : echec d'allocation simule ===
[OK]    (2.d) mat_lire renvoie MAT_ERR_ALLOCATION proprement

Bilan : 14 / 14 verifications reussies.
```

#### Exercice 3 : Calcul matriciel

[matrice_calcul.c](matrice_calcul.c)

##### Q5.1 :

Non. `const Matrice *` ne protège que les champs de la structure elle-même : on ne peut pas modifier `a->coef`, `a->nb_lignes` ou `a->nb_colonnes`. En revanche, les entiers pointés par `coef` restent modifiables (par exemple `a->coef[i][j] = 0`). Pour interdire cette affectation, il faudrait déclarer les coefficients eux-mêmes comme constants dans la structure.

##### Q5.2 :

Il s'agit du problème de l'aliasing. Si `res` désigne la même matrice que `a`, l'initialisation de `*res` avec `MATRICE_VIDE` écrase `a` avant même que ses données soient lues : la mémoire de `a` est perdue (fuite) et la fonction travaille sur une matrice vide. Sans erreur levée, le résultat serait faux.

##### Q5.3 :

Il y a trois boucles imbriquées, sur `a->nb_lignes`, `b->nb_colonnes` et `a->nb_colonnes`, donc la fonction effectue $n \times p \times q$ multiplications. Pour des matrices de dimensions 1000 × 1000, elle effectuerait 1 000 000 000 de multiplications.

##### Q5.4 :

En C, un dépassement de capacité sur des entiers signés provoque un comportement indéfini : on ne peut donc pas effectuer l'addition puis tester le résultat, il faut vérifier avant de calculer. Le test doit aussi tenir compte du signe des opérandes, sinon l'addition d'un nombre négatif lèverait à tort une erreur de dépassement alors qu'il n'y en a pas.

##### Résultat test :

```text
=== Exercice 3 : addition ===
[OK]    (3.a) (2 x 3) + (3 x 2) : MAT_ERR_DIMENSIONS
[OK]    (3.d) (2 x 3) + (2 x 3) : MAT_OK
[OK]    (3.c) a + b est correct
[OK]    a et b n'ont pas ete modifiees
[OK]    (3.b) le resultat possede sa propre memoire
[OK]    (3.c) INT_MAX + 1 : MAT_ERR_DEPASSEMENT
=== Exercice 3 : multiplication ===
[OK]    (3.e) (2 x 3) x (2 x 3) : MAT_ERR_DIMENSIONS
[OK]    (3.h) (2 x 3) x (3 x 2) : MAT_OK
[OK]    (3.g) a x c = (58 64 / 139 154)
[OK]    (3.f) (3 x 2) x (2 x 3) donne une matrice 3 x 3
[OK]    a et c n'ont pas ete modifiees
[OK]    (3.g) 2 x 10^10 depasse INT_MAX : MAT_ERR_DEPASSEMENT
=== Exercice 3 : cas particuliers ===
[OK]    resultat = entree refuse, a reste intacte
[OK]    (3.f) echec d'allocation : MAT_ERR_ALLOCATION, r vide

Bilan : 14 / 14 verifications reussies.
```

#### Exercice 4 : Démonstration complète

[main.c](main.c)

##### Q6.1 :

`mat_lire` est une fonction de bibliothèque : elle ne sait pas dans quel contexte elle est utilisée. Un programme en ligne de commande affiche ses erreurs sur `stderr` en texte brut, mais une interface graphique les afficherait dans une boîte de dialogue.

##### Q6.2 :

En lecture, `fclose` ne peut pas provoquer de perte de données : il libère simplement les ressources associées au fichier. Même s'il échoue, les données ont déjà été lues et sont en mémoire ; ignorer l'erreur est acceptable.

En écriture, c'est différent. Les données passées à `fwrite` ou `fprintf` ne sont pas nécessairement écrites sur le disque immédiatement. Tester `fclose` en écriture est donc indispensable pour signaler que le fichier de résultat est potentiellement incomplet ou corrompu.

##### Q6.3 :

Les trois matrices `a`, `b` et `r` ont été allouées avec succès, mais `sauvegarder` échoue. Il faut donc libérer **trois matrices**.

##### Résultat test :

```text
gcc -std=c11 -Wall -Wextra -Wpedantic -g matrice.c matrice_alloc.c matrice_io.c matrice_calcul.c main.c -o demo_matrices
PS C:\Users\L\Desktop\INSA CVL\Semester 1\Programmation C\td_matrices> ./demo_matrices add donnees/A.txt donnees/B.txt donnees/R_add.txt
A (4 x 3) :
       25       48       84
       15       33       11
       45       88       10
        0       12       -5
B (4 x 3) :
        1        2        3
        4        5        6
        7        8        9
       10       11       12
R = A + B (4 x 3) :
       26       50       87
       19       38       17
       52       96       19
       10       23        7
Résultat enregistré dans "donnees/R_add.txt".
PS C:\Users\L\Desktop\INSA CVL\Semester 1\Programmation C\td_matrices> ./demo_matrices mul donnees/B.txt donnees/C.txt donnees/R_mul.txt
A (4 x 3) :
        1        2        3
        4        5        6
        7        8        9
       10       11       12
B (3 x 2) :
        1        0
        0        1
        2       -1
R = A x B (4 x 2) :
        7       -1
       16       -1
       25       -1
       34       -1
Résultat enregistré dans "donnees/R_mul.txt".
PS C:\Users\L\Desktop\INSA CVL\Semester 1\Programmation C\td_matrices> ./demo_matrices add donnees/A.txt donnees/C.txt donnees/R_err.txt
A (4 x 3) :
       25       48       84
       15       33       11
       45       88       10
        0       12       -5
B (3 x 2) :
        1        0
        0        1
        2       -1
Erreur : dimensions incompatibles (A : 4 x 3, B : 3 x 2)
PS C:\Users\L\Desktop\INSA CVL\Semester 1\Programmation C\td_matrices> ./demo_matrices add donnees/invalide.txt donnees/B.txt donnees/R_err.txt
Erreur : lecture de "donnees/invalide.txt" : fichier mal formé
PS C:\Users\L\Desktop\INSA CVL\Semester 1\Programmation C\td_matrices> ./demo_matrices toto donnees/A.txt donnees/B.txt donnees/R.txt
Usage : C:\Users\L\Desktop\INSA CVL\Semester 1\Programmation C\td_matrices\demo_matrices.exe <add|mul> <fichier_A> <fichier_B> <fichier_R>
PS C:\Users\L\Desktop\INSA CVL\Semester 1\Programmation C\td_matrices>
```

---

## 4. Critères de validation finaux

| Critère | État | Référence |
|---|---|---|
| Tests unitaires de l'exercice 1 (`test_ex1`) | 16 / 16 vérifications réussies | [Exercice 1](#exercice-1--allocation-et-destruction) |
| Tests unitaires de l'exercice 2 (`test_ex2`) | 14 / 14 vérifications réussies | [Exercice 2](#exercice-2--entrées-sorties) |
| Tests unitaires de l'exercice 3 (`test_ex3`) | 14 / 14 vérifications réussies | [Exercice 3](#exercice-3--calcul-matriciel) |
| Compilation stricte `-std=c11 -Wall -Wextra -Wpedantic` | Aucun avertissement | [2.5. Makefile](#25-contenu-du-makefile) |
| Mémoire sous `valgrind` (`test_ex1`, `test_ex2`, `test_ex3`, `demo_matrices`) | 0 fuite, 0 accès invalide | [4.1](#41-vérifications-mémoire) |
| Programme `demo_matrices` | 10 scénarios validés (2, 6 et 8 présentés) | [4.2](#42-démonstration-finale) |
| Gestion d'erreurs | Dimensions incompatibles, fichier mal formé, échec d'écriture, usage incorrect | [Exercice 4](#exercice-4--démonstration-complète) et [4.2](#42-démonstration-finale) |

### 4.1. Vérifications mémoire

Les trois suites de tests unitaires (`test_ex1`, `test_ex2`, `test_ex3`) ainsi que le programme principal `demo_matrices` ont été passés sous `valgrind` avec 0 fuite mémoire et 0 accès invalide. Les rapports de `test_ex2` et de `test_ex3` sont reproduits ci-dessous ; celui du programme principal figure dans le [scénario 8](#scénario-8--échec-décriture-du-fichier-de-sortie).

#### test ex2

```text
HEAP SUMMARY:
    in use at exit: 0 bytes in 0 blocks
  total heap usage: 51 allocs, 51 frees, 49,976 bytes allocated

All heap blocks were freed -- no leaks are possible
```

#### test ex3

```text
HEAP SUMMARY:
    in use at exit: 0 bytes in 0 blocks
  total heap usage: 37 allocs, 37 frees, 1,412 bytes allocated

All heap blocks were freed -- no leaks are possible
```

### 4.2. Démonstration finale

Les scénarios ci-dessous (2, 6 et 8) sont des exemples représentatifs parmi les 10 scénarios intégralement validés lors du projet.

```text
$ gcc -std=c11 -Wall -Wextra -Wpedantic -g main.c matrice.c matrice_alloc.c matrice_io.c matrice_calcul.c -o demo_matrices
$
```

#### Scénario 2 : multiplication correcte

```text
$ ./demo_matrices mul donnees/A.txt donnees/C.txt R_scenario2.txt
A (4 x 3) :
       25       48       84
       15       33       11
       45       88       10
        0       12       -5
B (3 x 2) :
        1        0
        0        1
        2       -1
R = A x B (4 x 2) :
      193      -36
       37       22
       65       78
      -10       17
Résultat enregistré dans "R_scenario2.txt".
$ echo $?
0
```

Résultat attendu : aucune erreur levée et résultat correct.

#### Scénario 6 : fichier mal formé

```text
$ ./demo_matrices add donnees/invalide.txt donnees/B.txt R_scenario6.txt
Erreur : lecture de "donnees/invalide.txt" : fichier mal formé
$ echo $?
1
```

Résultat attendu : erreur levée à cause du fichier mal formé, avec le nom du fichier concerné.

#### Scénario 8 : échec d'écriture du fichier de sortie

```text
$ valgrind --leak-check=full ./demo_matrices add donnees/A.txt donnees/B.txt "$DOSSIER_ABSENT/R_scenario8.txt"
==2256== Memcheck, a memory error detector
==2256== Copyright (C) 2002-2024, and GNU GPL'd, by Julian Seward et al.
==2256== Using Valgrind-3.26.0 and LibVEX; rerun with -h for copyright info
==2256== Command: ./demo_matrices add donnees/A.txt donnees/B.txt /R_scenario8.txt
==2256==
A (4 x 3) :
       25       48       84
       15       33       11
       45       88       10
        0       12       -5
B (4 x 3) :
        1        2        3
        4        5        6
        7        8        9
       10       11       12
R = A + B (4 x 3) :
       26       50       87
       19       38       17
       52       96       19
       10       23        7
Erreur : impossible de créer "/R_scenario8.txt" : Permission denied
==2256==
==2256== HEAP SUMMARY:
==2256==     in use at exit: 0 bytes in 0 blocks
==2256==   total heap usage: 23 allocs, 23 frees, 3,726 bytes allocated
==2256==
==2256== All heap blocks were freed -- no leaks are possible
==2256==
==2256== For lists of detected and suppressed errors, rerun with: -s
==2256== ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 0 from 0)
$ echo $?
1
```

La variable `$DOSSIER_ABSENT` étant vide, le chemin de sortie résolu est `/R_scenario8.txt`, à la racine du système, où l'écriture est refusée. Il s'agit donc d'un échec d'ouverture/écriture (permission refusée, chemin invalide).

Résultat attendu : l'erreur est signalée proprement (message explicite et code de retour 1) et toutes les matrices allouées sont libérées (23 allocations, 23 libérations). Ce scénario prouve la résistance du programme aux erreurs d'entrées-sorties.

### 4.3. Bilan et difficultés

- **Multiplication `R_mul`** : la commande `demo_matrices mul donnees/B.txt donnees/C.txt` calcule bien le produit matriciel $B \times C$ ($4 \times 3$ par $3 \times 2$, soit une matrice $4 \times 2$). Le programme affiche de façon générique « A » pour le premier fichier passé en argument et « B » pour le second, ce qui avait fait croire à tort que le résultat ne correspondait pas à $A \times C$.
- **`fflush`** : compréhension de son rôle (vidage du tampon sans fermeture du flux).

#### Répartition du travail

- **GUEYE Mame Cheikh** : Exercices 1 et 4, Makefile.
- **GUINARD Samuel ARMEL** : Exercices 2 et 3.
- **Travail conjoint** : tout le reste, le rapport compris.

#### Aides extérieures

Aide de l'IA pour répondre aux questions et pour la mise en page du README.
