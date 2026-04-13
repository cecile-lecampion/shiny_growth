# Function to process datafiles
process_datafile <- function(pattern, var1, var2, num_days, dirpath) {
  # 1. Lister les fichiers correspondant au pattern dans le dossier
  files <- list.files(path = dirpath, pattern = pattern, full.names = TRUE)
  if (length(files) == 0) {
    stop("Aucun fichier trouvé correspondant au pattern dans le dossier spécifié.")
  }

  # 2. Fonction pour charger un fichier et nommer la colonne
  load_data <- function(file) {
    # Vérification de l'existence du fichier
    if (!file.exists(file)) stop(paste("Fichier introuvable:", file))
    # Lecture du fichier, une seule colonne 'Length'
    df <- tryCatch(
      read.csv(file, header = FALSE, col.names = "Length", stringsAsFactors = FALSE),
      error = function(e) {
        warning(paste("Erreur de lecture du fichier:", file, e$message))
        return(NULL)
      }
    )
    return(df)
  }

  # 3. Charger tous les fichiers dans une liste
  Liste <- lapply(files, load_data)
  # Retirer les éléments NULL (fichiers non lus)
  Liste <- Liste[!sapply(Liste, is.null)]
  if (length(Liste) == 0) stop("Aucune donnée valide chargée.")

  # 4. Ajouter le nom du fichier comme colonne 'Name' (sans extension)
  names(Liste) <- tools::file_path_sans_ext(basename(files))
  Liste <- mapply(function(df, name) {
    df$Name <- name
    return(df)
  }, Liste, names(Liste), SIMPLIFY = FALSE)

  # 5. Séparer la colonne 'Name' en 2 colonnes (Line, Inhibitor_concentration)
  Liste <- lapply(Liste, function(df) {
    tidyr::separate(df, col = "Name", into = c(var1, var2), sep = "_", remove = TRUE)
  })

  # 6. Fusionner toutes les données dans un seul data.frame
  df <- data.table::rbindlist(Liste, use.names = TRUE, fill = TRUE)

  # Ajout de la colonne Day (Day1 à DayN)
  n <- nrow(df)
  days <- paste0("Day", rep(1:num_days, length.out = n))
  df$Day <- days

  return(df)
}

# ======================================================================
# Function to prepare AZ0 and AZ dataframes with statistics
# ======================================================================
prepare_dose_effect_data <- function(result_df, var1, var2) {
  # S'assurer que var2 est numérique
  result_df[[var2]] <- as.numeric(result_df[[var2]])
  
  # 2. Séparation des données contrôle (AZ0) et test (AZ)
  AZ0_df <- subset(result_df, result_df[[var2]] == 0)
  AZ_df  <- subset(result_df, result_df[[var2]] != 0)
  
  # Vérifier que les données existent
  if (nrow(AZ0_df) == 0) {
    stop("No control data (concentration = 0) found in the dataset.")
  }
  
  if (nrow(AZ_df) == 0) {
    stop("No treatment data (concentration != 0) found in the dataset.")
  }
  
  # 3. Calcul des statistiques pour le contrôle (AZ0)
  summary_AZ0 <- AZ0_df %>%
    dplyr::group_by(Day, .data[[var1]]) %>%
    dplyr::summarise(
      mean_AZ0 = mean(Length, na.rm = TRUE),
      sd_AZ0   = sd(Length, na.rm = TRUE),
      se_AZ0   = sd(Length, na.rm = TRUE) / sqrt(sum(!is.na(Length))),
      .groups = 'drop'
    ) 
  
  # 4. Fusion des statistiques contrôle avec les données test
  merge_cols <- c("Day", var1)
  AZ_df <- merge(AZ_df, summary_AZ0, by = merge_cols, all.x = TRUE)
  
  # 5. Calcul du pourcentage AZ/AZ0 pour chaque mesure
  AZ_df$Percent_AZ0 <- (AZ_df$Length / AZ_df$mean_AZ0) * 100
  
  # 6. Calcul des statistiques sur le pourcentage AZ/AZ0
  summary_AZ <- AZ_df %>%
    dplyr::group_by(Day, .data[[var2]], .data[[var1]]) %>%
    dplyr::summarise(
      mean = mean(Percent_AZ0, na.rm = TRUE),
      sd   = sd(Percent_AZ0, na.rm = TRUE),
      se   = sd(Percent_AZ0, na.rm = TRUE) / sqrt(sum(!is.na(Percent_AZ0))),
      n    = sum(!is.na(Percent_AZ0)),
      .groups = 'drop'
    ) 

  return(list(
    AZ0_df = AZ0_df,
    AZ_df = AZ_df,
    summary_AZ0 = summary_AZ0,
    summary_AZ = summary_AZ
  ))
}



# ======================================================================
# Function to create dose-effect curve plot
# ======================================================================
create_dose_effect_plot <- function(summary_AZ, AZ_df_No_NA, day_selected, var1, var2, colors = NULL, var1_order = NULL, base_size = 16) {
  # IMPORTANT: Convertir en data.frame pur et dégrouper
  plot_data <- summary_AZ %>%
    ungroup() %>%
    filter(Day == day_selected) %>%
    as.data.frame()
  
  if (nrow(plot_data) == 0) {
    stop(paste("No data available for", day_selected))
  }
  
  # Appliquer l'ordre personnalisé si fourni
  if (!is.null(var1_order) && length(var1_order) > 0) {
    plot_data[[var1]] <- factor(plot_data[[var1]], levels = var1_order)
  }
  
  # Générer des couleurs par défaut si nécessaire
  if (is.null(colors) || any(is.null(colors)) || any(colors == "")) {
    unique_levels <- if (!is.null(var1_order)) var1_order else unique(plot_data[[var1]])
    colors <- RColorBrewer::brewer.pal(max(3, length(unique_levels)), "Set2")[1:length(unique_levels)]
    names(colors) <- unique_levels
  }
  
  # ANALYSE STATISTIQUE PAR CONCENTRATION
  # STRATEGY: Compare between lines at each concentration
  # PURPOSE: Statistical significance for each concentration point
  
  # Filtrer les données brutes pour le jour sélectionné
  raw_data_day <- AZ_df_No_NA %>%
    filter(Day == day_selected)
  
  # Obtenir les concentrations uniques (excluant 0)
  concentrations <- sort(unique(raw_data_day[[var2]]))
  concentrations <- concentrations[concentrations != 0]
  
  # Analyse statistique pour chaque concentration
  stats_by_conc <- list()
  
  for (conc in concentrations) {
    conc_data <- raw_data_day %>%
      filter(.data[[var2]] == conc)
    
    if (nrow(conc_data) > 0 && length(unique(conc_data[[var1]])) > 1) {
      # Test de normalité
      shapiro_results <- conc_data %>%
        dplyr::group_by(.data[[var1]]) %>%
        dplyr::summarise(
          n = dplyr::n(),
          p_shapiro = if (dplyr::n() >= 3 && dplyr::n() <= 5000) {
            shapiro.test(Percent_AZ0)$p.value
          } else { NA_real_ },
          .groups = 'drop'
        )
      
      # Décision sur la normalité
      is_normal <- all(shapiro_results$p_shapiro > 0.05, na.rm = TRUE)
      
      if (is_normal) {
        # ANOVA
        anova_result <- conc_data %>%
          anova_test(as.formula(paste("Percent_AZ0 ~", var1)))
        
        stats_by_conc[[as.character(conc)]] <- list(
          concentration = conc,
          test_type = "ANOVA",
          p_value = anova_result$p,
          significant = anova_result$p < 0.05,
          shapiro_results = shapiro_results,
          anova_results = anova_result
        )
        
        # Post-hoc si significatif
        if (anova_result$p < 0.05) {
          tukey_result <- conc_data %>%
            tukey_hsd(as.formula(paste("Percent_AZ0 ~", var1)))
          stats_by_conc[[as.character(conc)]]$posthoc_results <- tukey_result
        }
        
      } else {
        # Kruskal-Wallis
        kruskal_result <- conc_data %>%
          kruskal_test(as.formula(paste("Percent_AZ0 ~", var1)))
        
        stats_by_conc[[as.character(conc)]] <- list(
          concentration = conc,
          test_type = "Kruskal-Wallis",
          p_value = kruskal_result$p,
          significant = kruskal_result$p < 0.05,
          shapiro_results = shapiro_results,
          kruskal_results = kruskal_result
        )
        
        # Post-hoc si significatif
        if (kruskal_result$p < 0.05) {
          dunn_result <- conc_data %>%
            dunn_test(as.formula(paste("Percent_AZ0 ~", var1)), p.adjust.method = "BH")
          stats_by_conc[[as.character(conc)]]$posthoc_results <- dunn_result
        }
      }
    }
  }
  
  # Créer le graphique
  p <- ggplot(plot_data, aes(x = .data[[var2]], y = mean,
                             group = .data[[var1]], color = .data[[var1]])) +
    geom_line(linewidth = 1.5) +
    geom_point(size = 3) +
    geom_errorbar(aes(ymin = mean - se, ymax = mean + se), width = .1, linewidth = 1) +
    scale_x_continuous(trans = 'log10', 
                       labels = c(0, 0.01, 0.1, 1, 10)) +
    scale_color_manual(values = colors) +
    theme_light(base_size = base_size) +
    theme(
      panel.grid.major.x = element_blank(),
      panel.grid.minor.x = element_blank(),
      axis.title = element_text(size = base_size + 2, face = "bold"),
      axis.text = element_text(size = base_size - 2),
      legend.title = element_text(size = base_size, face = "bold"),
      legend.text = element_text(size = base_size - 2),
      plot.title = element_text(size = base_size + 4, face = "bold")
    ) +
    labs(
      color = var1,
      x = var2,
      y = "Mean Growth (%)",
      title = paste("Dose-Effect Curve -", day_selected)
    ) +
    annotation_logticks(sides = "b")
  
  # Ajouter les annotations de significativité
  # STRATEGY: Add significance indicators at each concentration
  if (length(stats_by_conc) > 0) {
    sig_annotations <- data.frame()
    for (conc_name in names(stats_by_conc)) {
      stat_info <- stats_by_conc[[conc_name]]
      if (stat_info$significant) {
        sig_annotations <- rbind(sig_annotations, data.frame(
          x = as.numeric(conc_name),
          y = max(plot_data$mean + plot_data$se) * 1.1,
          label = "*"
        ))
      }
    }
    
    if (nrow(sig_annotations) > 0) {
      p <- p + geom_text(data = sig_annotations,
                         aes(x = x, y = y, label = label),
                         inherit.aes = FALSE, size = base_size / 4, color = "red")
    }
  }
  
  return(list(
    plot = p,
    statistics = stats_by_conc
  ))
}

# ======================================================================
# Function to create distribution plot with all days (CORRECTED)
# ======================================================================
create_violin_plot <- function(AZ_df_No_NA, var1, var2, colors = NULL, var1_order = NULL, base_size = 16) {
  
  # S'assurer que les données sont valides
  if (is.null(AZ_df_No_NA) || nrow(AZ_df_No_NA) == 0) {
    stop("No data provided for violin plot.")
  }
  
  # Appliquer l'ordre personnalisé si fourni
  if (!is.null(var1_order) && length(var1_order) > 0) {
    # S'assurer que seules les valeurs présentes dans les données sont utilisées comme niveaux
    available_levels <- intersect(var1_order, unique(AZ_df_No_NA[[var1]]))
    if (length(available_levels) > 0) {
      AZ_df_No_NA[[var1]] <- factor(AZ_df_No_NA[[var1]], levels = available_levels)
    }
  } else {
    # Sinon, convertir en facteur pour assurer un ordre cohérent
    AZ_df_No_NA[[var1]] <- as.factor(AZ_df_No_NA[[var1]])
  }
  
  # Convertir var2 en facteur pour l'axe des x, en s'assurant que 0 vient en premier
  AZ_df_No_NA[[var2]] <- factor(AZ_df_No_NA[[var2]], levels = sort(unique(as.numeric(as.character(AZ_df_No_NA[[var2]])))))
  
  # Générer des couleurs par défaut si nécessaire
  if (is.null(colors) || any(is.null(colors)) || any(colors == "")) {
    unique_levels <- levels(AZ_df_No_NA[[var1]])
    colors <- RColorBrewer::brewer.pal(max(3, length(unique_levels)), "Set2")[1:length(unique_levels)]
    names(colors) <- unique_levels
  }
  
  # Créer le graphique
  p <- ggplot(AZ_df_No_NA, aes(x = .data[[var2]], y = Percent_AZ0, color = .data[[var1]])) +
    # Utiliser geom_jitter ou geom_quasirandom
    ggbeeswarm::geom_quasirandom(size = 2, alpha = 0.7, dodge.width = 0.8) +
    # Ajouter la moyenne comme un point noir
    stat_summary(fun = mean, geom = "point", shape = 18, size = 4, color = "black",
                 position = position_dodge(width = 0.8)) +
    # Appliquer les couleurs personnalisées
    scale_color_manual(values = colors) +
    # Créer des facettes pour chaque jour et chaque groupe
    facet_grid(rows = vars(.data[[var1]]), cols = vars(Day), scales = "free_y") +
    theme_light(base_size = base_size) +
    theme(
      axis.title = element_text(size = base_size + 2, face = "bold"),
      axis.text = element_text(size = base_size - 2),
      axis.text.x = element_text(angle = 45, hjust = 1),
      legend.position = "none", # La couleur est redondante avec les facettes
      strip.text = element_text(size = base_size - 2, face = "bold"),
      plot.title = element_text(size = base_size + 4, face = "bold")
    ) +
    labs(
      x = var2,
      y = "Growth (% of Control)",
      color = var1,
      title = "Distribution of Growth by Day and Treatment"
    )
  
  return(list(
    plot = p,
    statistics = NULL  # Pas d'analyse statistique pour le violin plot
  ))
}

# ======================================================================
# Function to create bar plot for specific day and concentration
# ======================================================================
analyze_barplot_statistics <- function(plot_data, var1, analysis_mode = c("strict", "prefer_parametric")) {
  analysis_mode <- match.arg(analysis_mode)

  shapiro_results <- plot_data %>%
    dplyr::group_by(.data[[var1]]) %>%
    dplyr::summarise(
      n = dplyr::n(),
      p_shapiro = if (dplyr::n() >= 3 && dplyr::n() <= 5000) {
        shapiro.test(Percent_AZ0)$p.value
      } else {
        NA_real_
      },
      .groups = "drop"
    )

  sample_sizes_ok <- all(shapiro_results$n >= 3, na.rm = TRUE)
  shapiro_pass <- sample_sizes_ok && all(!is.na(shapiro_results$p_shapiro)) && all(shapiro_results$p_shapiro > 0.05)

  levene_results <- NULL
  levene_p <- NA_real_
  if (dplyr::n_distinct(plot_data[[var1]]) >= 2) {
    levene_results <- tryCatch(
      rstatix::levene_test(plot_data, as.formula(paste("Percent_AZ0 ~", var1))),
      error = function(e) {
        NULL
      }
    )

    if (!is.null(levene_results) && "p" %in% names(levene_results)) {
      levene_p <- levene_results$p[1]
    }
  }

  use_parametric <- FALSE
  decision_reason <- NULL

  if (analysis_mode == "strict") {
    use_parametric <- shapiro_pass
    decision_reason <- if (use_parametric) {
      "Strict rule selected: all groups passed Shapiro-Wilk, so ANOVA was retained."
    } else {
      "Strict rule selected: at least one group failed Shapiro-Wilk or had insufficient sample size, so Kruskal-Wallis was used."
    }
  } else {
    if (shapiro_pass) {
      use_parametric <- TRUE
      decision_reason <- "Permissive rule selected: all groups passed Shapiro-Wilk, so ANOVA was retained."
    } else if (sample_sizes_ok && !is.na(levene_p) && levene_p > 0.05) {
      use_parametric <- TRUE
      decision_reason <- "Permissive rule selected: some groups failed Shapiro-Wilk, but sample sizes were sufficient and Levene's test showed homogeneous variances, so ANOVA was retained."
    } else if (!sample_sizes_ok) {
      decision_reason <- "Permissive rule selected, but at least one group had fewer than 3 observations, so Kruskal-Wallis was used."
    } else if (!is.na(levene_p) && levene_p <= 0.05) {
      decision_reason <- "Permissive rule selected, but Levene's test indicated heterogeneous variances, so Kruskal-Wallis was used."
    } else {
      decision_reason <- "Permissive rule selected, but the parametric conditions were not sufficient, so Kruskal-Wallis was used."
    }
  }

  selected_test <- if (use_parametric) "ANOVA" else "Kruskal-Wallis"

  analysis_decision <- data.frame(
    analysis_mode = analysis_mode,
    selected_test = selected_test,
    decision_reason = decision_reason,
    sample_sizes_ok = sample_sizes_ok,
    shapiro_pass = shapiro_pass,
    levene_p = levene_p,
    stringsAsFactors = FALSE
  )

  list(
    shapiro_results = shapiro_results,
    levene_results = levene_results,
    analysis_decision = analysis_decision,
    selected_test = selected_test,
    decision_reason = decision_reason,
    use_parametric = use_parametric
  )
}

create_bar_plot <- function(AZ_df_No_NA, day_selected, conc_selected, var1, var2, colors = NULL, var1_order = NULL, base_size = 16, analysis_mode = c("strict", "prefer_parametric")) {
  analysis_mode <- match.arg(analysis_mode)
  # Filtrer les données 
  plot_data <- subset(AZ_df_No_NA, Day == day_selected & 
                      as.numeric(as.character(AZ_df_No_NA[[var2]])) == conc_selected)
  
  if (nrow(plot_data) == 0) {
    stop(paste("No data available for", day_selected, "and concentration", conc_selected))
  }
  
  # Appliquer l'ordre personnalisé si fourni
  if (!is.null(var1_order) && length(var1_order) > 0) {
    plot_data[[var1]] <- factor(plot_data[[var1]], levels = var1_order)
  }
  
  # STATISTICAL DECISION
  # STRATEGY: Choose parametric or non-parametric test based on the user rule
  # PURPOSE: Keep ANOVA when assumptions are acceptable, even if Shapiro is imperfect
  decision <- analyze_barplot_statistics(plot_data, var1, analysis_mode = analysis_mode)
  
  # Variables pour stocker les résultats statistiques
  main_test_result <- NULL
  posthoc_result <- NULL
  cld_letters <- NULL
  
  if (decision$use_parametric) {
    # ANOVA
    tryCatch({
      main_test_result <- plot_data %>%
        anova_test(as.formula(paste("Percent_AZ0 ~", var1)))
      
      # Post-hoc Tukey si significatif
      if (main_test_result$p < 0.05) {
        posthoc_result <- plot_data %>%
          tukey_hsd(as.formula(paste("Percent_AZ0 ~", var1)))
        
        # Générer les lettres CLD
        if (nrow(posthoc_result) > 0) {
          # Créer un vecteur nommé de p-values pour multcompView
          p_values <- setNames(posthoc_result$p.adj, 
                              paste(posthoc_result$group1, posthoc_result$group2, sep = "-"))
          
          tryCatch({
            cld_result <- multcompLetters(p_values, threshold = 0.05)
            cld_letters <- cld_result$Letters
          }, error = function(e) {
            cat("Error generating CLD letters:", e$message, "\n")
            # Fallback: créer des lettres simples
            groups <- unique(c(posthoc_result$group1, posthoc_result$group2))
            cld_letters <- setNames(letters[1:length(groups)], groups)
          })
        }
      }
      
    }, error = function(e) {
      cat("Error in ANOVA:", e$message, "\n")
    })
    
  } else {
    # Kruskal-Wallis
    tryCatch({
      main_test_result <- plot_data %>%
        kruskal_test(as.formula(paste("Percent_AZ0 ~", var1)))
      
      # Post-hoc Dunn si significatif
      if (main_test_result$p < 0.05) {
        posthoc_result <- plot_data %>%
          dunn_test(as.formula(paste("Percent_AZ0 ~", var1)), p.adjust.method = "BH")
        
        # Générer les lettres CLD pour Dunn
        if (nrow(posthoc_result) > 0) {
          p_values <- setNames(posthoc_result$p.adj, 
                              paste(posthoc_result$group1, posthoc_result$group2, sep = "-"))
          
          tryCatch({
            cld_result <- multcompLetters(p_values, threshold = 0.05)
            cld_letters <- cld_result$Letters
          }, error = function(e) {
            cat("Error generating CLD letters for non-parametric:", e$message, "\n")
            # Fallback: créer des lettres simples
            groups <- unique(c(posthoc_result$group1, posthoc_result$group2))
            cld_letters <- setNames(letters[1:length(groups)], groups)
          })
        }
      }
      
    }, error = function(e) {
      cat("Error in Kruskal-Wallis:", e$message, "\n")
    })
  }
  
  # Calculer les statistiques pour les données filtrées
  summary_data <- plot_data %>%
    dplyr::group_by(.data[[var1]]) %>%
    dplyr::summarise(
      mean = mean(Percent_AZ0, na.rm = TRUE),
      sd = sd(Percent_AZ0, na.rm = TRUE),
      se = sd(Percent_AZ0, na.rm = TRUE) / sqrt(sum(!is.na(Percent_AZ0))),
      .groups = 'drop'
    )
  
  # Appliquer l'ordre personnalisé aux données résumées
  if (!is.null(var1_order) && length(var1_order) > 0) {
    available_levels <- intersect(var1_order, summary_data[[var1]])
    if (length(available_levels) > 0) {
      summary_data[[var1]] <- factor(summary_data[[var1]], levels = available_levels)
    }
  }
  
  # Ajouter les lettres CLD aux données résumées
  if (!is.null(cld_letters)) {
    summary_data$cld <- cld_letters[as.character(summary_data[[var1]])]
    # Remplacer les NA par des lettres vides
    summary_data$cld[is.na(summary_data$cld)] <- ""
  }
  
  # Générer des couleurs par défaut si nécessaire
  if (is.null(colors) || any(is.null(colors)) || any(colors == "")) {
    unique_levels <- levels(summary_data[[var1]])
    if (is.null(unique_levels)) unique_levels <- unique(summary_data[[var1]])
    palette_size <- max(3, length(unique_levels))
    colors <- RColorBrewer::brewer.pal(palette_size, "Set2")[seq_along(unique_levels)]
    names(colors) <- unique_levels
  }
  
  # Créer le barplot avec barres d'erreur
  p <- ggplot(summary_data, aes(x = .data[[var1]], y = mean, fill = .data[[var1]])) +
    geom_bar(stat = "identity", alpha = 0.7) +
    geom_errorbar(aes(ymin = mean - se, ymax = mean + se),
                  width = 0.2, linewidth = 1) +
    scale_fill_manual(values = colors) +
    theme_light(base_size = base_size) +
    theme(
      axis.title = element_text(size = base_size + 2, face = "bold"),
      axis.text = element_text(size = base_size - 2),
      legend.title = element_text(size = base_size, face = "bold"),
      legend.text = element_text(size = base_size - 2),
      plot.title = element_text(size = base_size + 4, face = "bold")
    ) +
    labs(
      x = var1,
      y = "Growth (% of Control)",
      fill = var1,
      title = paste(day_selected, "-", var2, "=", conc_selected)
    )
  
  # Ajouter les lettres CLD au graphique si elles existent
  if (!is.null(cld_letters) && "cld" %in% names(summary_data)) {
    # Position y au-dessus des barres + erreur
    y_position <- summary_data$mean + summary_data$se + (max(summary_data$mean + summary_data$se, na.rm = TRUE) * 0.05)

    p <- p + geom_text(
      data = summary_data,
      aes(
        x = .data[[var1]],         # AJOUT: x requis par geom_text
        y = y_position,
        label = cld
      ),
      vjust = 0,
      size = base_size / 4,
      fontface = "bold",
      inherit.aes = FALSE
    )
  }
  
  # Préparer les résultats statistiques
  statistics <- list(
    is_normal = decision$use_parametric,
    analysis_mode = analysis_mode,
    selected_test = decision$selected_test,
    decision_reason = decision$decision_reason,
    shapiro_results = decision$shapiro_results,
    levene_results = decision$levene_results,
    analysis_decision = decision$analysis_decision,
    main_test = main_test_result,
    posthoc_test = posthoc_result,
    cld_letters = cld_letters
  )
  
  return(list(
    plot = p,
    statistics = statistics
  ))
}

# ======================================================================
# Robust export of statistical results to ZIP (supports curve/bar/violin)
# ======================================================================
create_statistical_export <- function(stats_results, filename_base = "statistical_results") {
  # Valider l’entrée
  if (is.null(stats_results)) {
    stop("No statistical results to export (stats_results is NULL).")
  }
  
  # Détecter le type de structure:
  # - Bar plot: list avec champs selected_test / analysis_decision / main_test / posthoc_test
  # - Curve: list par concentration (liste de sous-listes) avec test_type/p_value/posthoc_results
  # - Violin: stats_results == NULL (déjà géré plus haut)
  is_bar_like <- is.list(stats_results) && !is.null(stats_results$selected_test)
  is_curve_like <- is.list(stats_results) && !is_bar_like && length(stats_results) > 0 && all(sapply(stats_results, is.list))
  
  temp_dir <- tempdir()
  export_dir <- file.path(temp_dir, paste0(filename_base, "_", format(Sys.time(), "%Y%m%d_%H%M%S")))
  dir.create(export_dir, recursive = TRUE, showWarnings = FALSE)
  exported_files <- character(0)
  
  # Export BAR PLOT stats
  if (is_bar_like) {
    if (!is.null(stats_results$analysis_decision)) {
      decision_file <- file.path(export_dir, "analysis_decision.csv")
      write.csv(stats_results$analysis_decision, decision_file, row.names = FALSE)
      exported_files <- c(exported_files, decision_file)
    }

    # Normality (Shapiro per group)
    if (!is.null(stats_results$shapiro_results)) {
      shapiro_file <- file.path(export_dir, "shapiro_wilk_test.csv")
      write.csv(stats_results$shapiro_results, shapiro_file, row.names = FALSE)
      exported_files <- c(exported_files, shapiro_file)
    }

    if (!is.null(stats_results$levene_results)) {
      levene_file <- file.path(export_dir, "levene_test.csv")
      write.csv(stats_results$levene_results, levene_file, row.names = FALSE)
      exported_files <- c(exported_files, levene_file)
    }
    
    if (identical(stats_results$selected_test, "ANOVA") || isTRUE(stats_results$is_normal)) {
      if (!is.null(stats_results$main_test)) {
        anova_file <- file.path(export_dir, "anova_results.csv")
        write.csv(stats_results$main_test, anova_file, row.names = FALSE)
        exported_files <- c(exported_files, anova_file)
      }
      if (!is.null(stats_results$posthoc_test)) {
        tukey_file <- file.path(export_dir, "tukey_posthoc.csv")
        write.csv(stats_results$posthoc_test, tukey_file, row.names = FALSE)
        exported_files <- c(exported_files, tukey_file)
      }
    } else {
      if (!is.null(stats_results$main_test)) {
        kruskal_file <- file.path(export_dir, "kruskal_wallis_test.csv")
        write.csv(stats_results$main_test, kruskal_file, row.names = FALSE)
        exported_files <- c(exported_files, kruskal_file)
      }
      if (!is.null(stats_results$posthoc_test)) {
        dunn_file <- file.path(export_dir, "dunn_posthoc.csv")
        write.csv(stats_results$posthoc_test, dunn_file, row.names = FALSE)
        exported_files <- c(exported_files, dunn_file)
      }
    }
    
    # Export des lettres CLD si présentes
    if (!is.null(stats_results$cld_letters)) {
      cld_df <- data.frame(group = names(stats_results$cld_letters),
                           cld = unname(stats_results$cld_letters),
                           stringsAsFactors = FALSE)
      cld_file <- file.path(export_dir, "cld_letters.csv")
      write.csv(cld_df, cld_file, row.names = FALSE)
      exported_files <- c(exported_files, cld_file)
    }
  }
  
  # Export CURVE stats (par concentration)
  if (is_curve_like) {
    # Consolider en data.frame
    flat <- lapply(names(stats_results), function(conc) {
      s <- stats_results[[conc]]
      data.frame(
        concentration = as.numeric(conc),
        test_type = s$test_type %||% NA_character_,
        p_value = s$p_value %||% NA_real_,
        significant = s$significant %||% NA,
        stringsAsFactors = FALSE
      )
    })
    summary_curve <- do.call(rbind, flat)
    curve_summary_file <- file.path(export_dir, "curve_summary_by_concentration.csv")
    write.csv(summary_curve, curve_summary_file, row.names = FALSE)
    exported_files <- c(exported_files, curve_summary_file)
    
    # Export des posthoc par concentration si présents
    for (conc in names(stats_results)) {
      s <- stats_results[[conc]]
      if (!is.null(s$posthoc_results)) {
        f <- file.path(export_dir, paste0("posthoc_", gsub("\\.", "_", conc), ".csv"))
        write.csv(s$posthoc_results, f, row.names = FALSE)
        exported_files <- c(exported_files, f)
      }
    }
    
    # Export des tableaux Shapiro par concentration si présents
    for (conc in names(stats_results)) {
      s <- stats_results[[conc]]
      if (!is.null(s$shapiro_results)) {
        f <- file.path(export_dir, paste0("shapiro_", gsub("\\.", "_", conc), ".csv"))
        write.csv(s$shapiro_results, f, row.names = FALSE)
        exported_files <- c(exported_files, f)
      }
    }
  }
  
  # Fichier de résumé
  summary_file <- file.path(export_dir, "analysis_summary.txt")
  summary_lines <- c(
    "Statistical Analysis Summary",
    "===========================",
    paste("Analysis date:", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
    paste("Structure detected:", if (is_bar_like) "bar" else if (is_curve_like) "curve" else "unknown")
  )

  if (is_bar_like) {
    summary_lines <- c(
      summary_lines,
      paste("Selected test:", stats_results$selected_test %||% "unknown"),
      paste("Analysis mode:", stats_results$analysis_mode %||% "unknown"),
      paste("Decision reason:", stats_results$decision_reason %||% "none")
    )
  }

  summary_lines <- c(
    summary_lines,
    "",
    "Exported files:",
    if (length(exported_files) > 0) paste("-", basename(exported_files), collapse = "\n") else "- none"
  )

  summary_text <- paste(summary_lines, collapse = "\n")
  writeLines(summary_text, summary_file)
  exported_files <- c(exported_files, summary_file)
  
  # Créer le ZIP
  zip_file <- file.path(temp_dir, paste0(filename_base, ".zip"))
  old_wd <- getwd()
  setwd(export_dir)
  on.exit(setwd(old_wd), add = TRUE)
  zip(zip_file, files = basename(exported_files))
  
  return(zip_file)
}
