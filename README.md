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