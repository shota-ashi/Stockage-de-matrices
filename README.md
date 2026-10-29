# Stockage-de-matrices

**Binôme :** GUEYE Mame Cheikh  & GUINARD Samuel ARMEL   
  
---

## Réponses aux questions de réflexion (Exercice 1)

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

### Q4.1 :
Cela permet de garantir que le résultat n’est transmis à *res que si toute la lecture réussit. Cela permet de valider le principe d'atomicité de la fonction en ne renvoyant que soit la matrice entièrement lue, soit une matrice vide.

### Q4.2 :
Non. La fonction utilise fscanf qui lit des mots séparé par des caractères de séparation peut importe lequel. Ce n’est pas gênant car le nombre de lignes et de colonnes indique combien de coefficients doivent être lus. Le principe « tolérant en lecture, strict en écriture » est bien respecter car la sortie est prévisible mais que que le programme accepte plusieurs présentations valides des données.

### Q4.3 :
Il suffit d’écrire les deux matrices successivement dans le même fichier avec deux appels à mat_ecrire sans fermer le fichier entre les deux écritures.

### Q4.4 :
fflush permet de forcer l’écriture des données se trouvant dans le tampon du flux de sortie. Cela ne dispense pas l’appelant d'appeler fclose car fflush n'a aucun action sur la fermeture du fichier

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









Vérifications mémoire :

test_ex2
HEAP SUMMARY:
in use at exit: 0 bytes in 0 blocks
total heap usage: 51 allocs, 51 frees, 49,976 bytes allocated

All heap blocks were freed -- no leaks are possible