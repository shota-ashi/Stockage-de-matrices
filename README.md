# Stockage-de-matrices

**Binôme :** GUEYE Mame Cheikh  & GUINARD Samuel ARMEL   
  
---

## Réponses aux questions de réflexion (Exercice 1)
[matrice.c](matrice.c) [matrice_alloc.c](matrice_alloc.c)

### Q3.1 : 
Le passage par pointeur (`Matrice *`) est indispensable pour modifier directement la variable de l'appelant. Cela permet de remettre son pointeur interne à `NULL` et ses dimensions à 0 après la libération. 

Si on passait la structure par valeur, la fonction ne travaillerait que sur une copie locale. La mémoire dynamique sur le tas serait bien libérée, mais la variable d'origine conserverait l'ancienne adresse mémoire, ce qui exposerait l'appelant à des accès invalides ou des erreurs

### Q3.2 :
Pour une matrice de $n \times p$ :
* **Nombre d'appels à `calloc` :** $n + 1$ (un premier appel pour le tableau de pointeurs de lignes, puis $n$ appels pour chaque ligne).
* **Nombre d me d'appels à `free` :** $n + 1$ (libération des $n$ lignes puis du tableau de pointeurs).

Si la $k$-ième allocation échoue, `mat_allouer` doit annuler les opérations précédentes en effectuant **$k - 1$ libérations**

### Q3.3 :
Appeler deux fois de suite `mat_detruire(&a)` est sans danger car le premier passage remet le pointeur de données à `NULL`. Lors du second passage, la fonction détecte le pointeur nul (ou exécute `free(NULL)`), ce qui n'a aucun effet en C.

En revanche, si on fait `Matrice b = a;`, C réalise une copie superficielle : `a` et `b` partagent la même adresse mémoire pour leurs données. Détruire `a` libère la mémoire et met le pointeur de `a` à `NULL`, mais `b` pointe toujours vers la zone libérée. L'appel `mat_detruire(&b)` tente alors de libérer un bloc déjà restitué, déclenchant un comportement indéfini

### Q3.4 : Initialisation systématique avec `MATRICE_VIDE`
Commencer par `*res = MATRICE_VIDE` garantit que la variable reçue est immédiatement dans un état valide et prévisible (pointeur à `NULL`, dimensions à 0). Si la fonction échoue ensuite (dimensions hors limites ou échec de `calloc`), la matrice de l'appelant reste propre au lieu de conserver des valeurs poubelles non initialisées

### Résultat test :

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

## Réponses aux questions de réflexion (Exercice 2)
[matrice_io.c](matrice_io.c)

### Q4.1 :
Cela permet de garantir que le résultat n’est transmis à *res que si toute la lecture réussit. Cela permet de valider le principe d'atomicité de la fonction en ne renvoyant que soit la matrice entièrement lue, soit une matrice vide.

### Q4.2 :
Non. La fonction utilise fscanf qui lit des mots séparé par des caractères de séparation peut importe lequel. Ce n’est pas gênant car le nombre de lignes et de colonnes indique combien de coefficients doivent être lus. Le principe « tolérant en lecture, strict en écriture » est bien respecter car la sortie est prévisible mais que que le programme accepte plusieurs présentations valides des données.

### Q4.3 :
Il suffit d’écrire les deux matrices successivement dans le même fichier avec deux appels à mat_ecrire sans fermer le fichier entre les deux écritures.

### Q4.4 :
fflush permet de forcer l’écriture des données se trouvant dans le tampon du flux de sortie. Cela ne dispense pas l’appelant d'appeler fclose car fflush n'a aucun action sur la fermeture du fichier

### Résultat test : 

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

## Réponses aux questions de réflexion (Exercice 3)
[matrice_calcul.c](matrice_calcul.c)

### Q5.1 :
Non const ne protège que les champs de la structure. Pour interdire cette affectation, il faudrait modifier la structure même en mettant les coefficients constants.

### Q5.2 :
Pour le problème de l'aliasing. Dans l'implémentation la matrice a serais écrasée par la matrice null et la fonction renverrais b si le programme ne soulève pas d'erreur.

### Q5.3 :
Il y a trois boucles imbriquées en a->nb_lignes, b->nb_colonnes, a->nb_colonnes donc la fonction effectue n*p*q multiplications. Pour des matrices de dimensions 1000*1000 la fonction effectuerais 1 000 000 000 multiplications

### Q5.4 :
Car en C un dépassement de capacité pour une opération sur des entiers signés provoque un comportement indéfini et qu'additionner a à un nombre négatif soulèverais l'erreur bien qu'il n'y en n’a pas.

### Résultat test : 

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

## Réponses aux questions de réflexion (Exercice 4)
[main.c](main.c)

### Q6.1 : 
`mat_lire` est une fonction de bibliothèque : elle ne sait pas dans quel contexte elle est utilisée. Un programme en ligne de commande affiche ses erreurs sur `stderr` en texte brut, mais une interface graphique les afficherait dans une boîte de dialogue


### Q6.2 :

En lecture, `fclose` ne peut pas provoquer de perte de données : il libère simplement les ressources associées au fichier. Même s'il échoue, les données ont déjà été lues et sont en mémoire ; ignorer l'erreur est acceptable.

En écriture, c'est différent. Les données passées à `fwrite` ou `fprintf` ne sont pas nécessairement écrites sur le disque immédiatement.Tester `fclose` en écriture est donc indispensable pour signaler que le fichier de résultat est potentiellement incomplet ou corrompu.

### Q6.3 :

Les trois matrices `a`, `b` et `r` ont été allouées avec succès, mais `sauvegarder` échoue. Il faut donc libérer **trois matrices**.

### Résultat test : 

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
R├®sultat enregistr├® dans "donnees/R_add.txt".
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
R├®sultat enregistr├® dans "donnees/R_mul.txt".
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
Erreur : lecture de "donnees/invalide.txt" : fichier mal form├®
PS C:\Users\L\Desktop\INSA CVL\Semester 1\Programmation C\td_matrices> ./demo_matrices toto donnees/A.txt donnees/B.txt donnees/R.txt
Usage : C:\Users\L\Desktop\INSA CVL\Semester 1\Programmation C\td_matrices\demo_matrices.exe <add|mul> <fichier_A><fichier_B> <fichier_R>
PS C:\Users\L\Desktop\INSA CVL\Semester 1\Programmation C\td_matrices> 





## Vérifications mémoire :

### test ex2
HEAP SUMMARY:
in use at exit: 0 bytes in 0 blocks
total heap usage: 51 allocs, 51 frees, 49,976 bytes allocated

All heap blocks were freed -- no leaks are possible

### test ex3
HEAP SUMMARY:
in use at exit: 0 bytes in 0 blocks
total heap usage: 37 allocs, 37 frees, 1,412 bytes allocated

All heap blocks were freed -- no leaks are possible



## Démonstration finale

$ gcc -std=c11 -Wall -Wextra -Wpedantic -g main.c matrice.c matrice_alloc.c matrice_io.c matrice_calcul.c -o demo_matrices
$

### Sénario 2 :
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

Résultat attendu pas d’erreur soulevée et résultat correct.

### Sénario 6 :
$ ./demo_matrices add donnees/invalide.txt donnees/B.txt R_scenario6.txt
Erreur : lecture de "donnees/invalide.txt" : fichier mal formé
$ echo $?
1

Résultat attendu erreur soulevée sur la mal formation du fichier et le fichier est nommé.

### Sénario 8 :                                          
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

Résultat attendu erreur soulevée pour la création sur l‘absence du dossier et les matrices allouées sont libérées.

## Bilan et difficultés

R_mult ne correspond pas à la multiplication de A et C et à provoquer un doute.
Compression de ce que fait fflush.

### Répartition du travail 


### Aides extérieures 

Aide ia pour pouvoir répondre aux questions.