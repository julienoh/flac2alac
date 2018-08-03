#!/bin/bash

# 07/02/2010
#
# Totale fichiers ENCODE :
# Totale fichiers NO ENCODE :
# Totale fichiers ERREUR ENCODE :
# Totale fichiers traitées :
#
# 
# Structure des répertories
# Les répertoires sont créés par l'outil MuiscBrainz Picard qui classe et Tag les pistes audios dans des répertoires de la forme :
# ARTISTE/ALBUM/TRACK - TITRE ou ARTISTE/ALBUM/CD - TARCK - TITRE
# 
# Pour fonctionner ce script utilise :
# - ffmpeg
# - AtomicParsley (pour les TAGs)
# - MusicBrainz (les musiques doivent être TAGGéeS avec MusicBrainz pour que AtomicParsley fonctionne lors d'importation des TAGs)

# Variables Globales
# La fonction "Fonction_debut" initialise les variables du script

# Fonction du script
# flac --> alac
# flac --> aac



Fonction_usage()
{
	#basname
	echo test
	
	#DIR_SRC
	#DIR_DEST
}

Fonction_test_env()
{
	command -v AtomicParsley >/dev/null 2>&1 || { echo >&2 "ERREUR, AtomicParsley n'est pas installé"; exit 1; }
        command -v ffmpeg >/dev/null 2>&1 || { echo >&2 "ERREUR, ffmpeg n'est pas installé"; exit 1; }
}

# Cette fonction initialise les variables du script
Fonction_debut()
{
	# $IFS variable determine what the field separators are. By default $IFS is set to the space character
	SAVEIFS=${IFS}
	IFS=$(echo -en "\n\b")
	REP_SRC="/media/nas/BIG_JUL/1_flac"
	#REP_SRC="/media/nas/BIG_JUL/1_flac/David Visan/Buddha-Bar V"
	ENCODE_TYPE="m4a"
	REP_DEST="1_alac"
	#REP_DEST="1_aac"
	DATENOW=`date '+%d-%m-%Y'`
	LOG=/media/nas/BIG_JUL/${REP_DEST}/flac_2_encode-${DATENOW}.log
	# Pour retagger -> A mettre à 0
	RETAG="1"
	echo "###############################" > $LOG
	echo ""
	echo "LOG de FLAC_2_ENCODE" >> $LOG
	echo ""
	date >> $LOG
	echo ""
	echo " Légende :"  >> $LOG
 	echo " ---------"  >> $LOG
	echo " ENCODE : Le fichier a été encodé"  >> $LOG
	echo " NO ENCODE : Le fichier n'a pas été encodé car il existe déjà"  >> $LOG
	echo " ERREUR ENCODE : Il y a une erreur lors de l'execution de ffmpeg "  >> $LOG
	echo ""
	echo "###############################" >> $LOG
	
	echo ""
	echo ""
	echo ""
	echo "         Début du Traitement [ ffmpeg ] pour FLAC_2_ENCODE"
	echo ""
	echo ""
	echo ""
}

# Fonction qui liste tous les répértoires puis qui tests la présence de fichier FLAC à l'intérieur.
Fonction_spider_rep()
{
	for k in `find ${REP_SRC} -type d`
	do

		file "${k}"/* | grep "FLAC audio bitstream data" > /dev/null
		if [ "$?" -eq "0" ];then
			# Fichiers Flac présents [ Appel Fonction_encode ]
			#echo "Fichiers Flac présents dans [ "${k}" ]" >> $LOG
			# Création du répertoire de destination si il n'existe pas
			RELATIF_REP_DEST=`echo "${k}" | sed 's/1_flac/'${REP_DEST}'/'`
			mkdir -p "${RELATIF_REP_DEST}"
			echo "traitement de [ ${RELATIF_REP_DEST} ]"
			#echo "traitement de [ ${k}]"
			###############
			Fonction_encode
			###############
           	# Changement des droits pour que le fichier de destination ait les mêmes que celui d'origine
            # Ceci est utile si le répertoire est monté via NFS par exemple
            # chown -R `ls -l "${k}" | tail -1 | awk '{print $3":"$4}'` "${RELATIF_REP_DEST}"
			#return 0
		else
			echo "Fichier Flac NON présents dans [ "${k}" ]" >> $LOG
			#return 1
		fi
	done

}

# Fonction qui récupère les TAGS d'un fichier Audio
# Recois en parametre le "titre.flac"
Fonction_get_tag()
{
	ARTIST=$(metaflac "$1" --show-tag=ARTIST | sed s/.*=//)
	ALBUMARTIST=$(metaflac "$1" --show-tag=ALBUMARTIST | sed s/.*=//)
	TITLE=$(metaflac "$1" --show-tag=TITLE | sed s/.*=//)
	ALBUM=$(metaflac "$1" --show-tag=ALBUM | sed s/.*=//)
	GENRE=$(metaflac "$1" --show-tag=GENRE | sed s/.*=//)
	TRACKNUMBER=$(metaflac "$1" --show-tag=TRACKNUMBER | sed s/.*=//)
	DISCNUMBER=$(metaflac "$1" --show-tag=DISCNUMBER | sed s/.*=//)
	COMPILATION=$(metaflac "$1" --show-tag=COMPILATION | sed s/.*=//)
}


# Fonction qui TAG un fichier Audio
Fonction_set_tag()
{
	/usr/bin/AtomicParsley "${1}" --overWrite \
	--artist "${ARTIST}" \
	--title "${TITLE}" \
	--album "${ALBUM}" \
	--genre "${GENRE}" \
	--tracknum "${TRACKNUMBER}" \
	--disk "${DISCNUMBER}" \
	--albumArtist "${ALBUMARTIST}" \
	--compilation "${COMPILATION}"


}

Fonction_encode()
{	
	# Récupere le "titre.flac" via le nom du fichier dans "$i"
	for i in `file -F ";:;" ${k}/* | grep "FLAC audio bitstream data" | awk -F ";:;" '{print $1}'`
	do
		#FLAC2M4A=`echo "${i}" | sed 's/\.flac/\.m4a/'`
		#FLAC2ALAC=`echo "${FLAC2M4A}" | sed 's/1_flac/1_Alac/'`
	
		FLAC_2_ENCODE=`echo "${i}" | sed 's/\.flac/\.'${ENCODE_TYPE}'/'`
		FLAC_2_ENCODE_DIR=`echo "${FLAC_2_ENCODE}" | sed 's/1_flac/'${REP_DEST}'/'`
		
		# Test si le répertoire de destination existe pour ne pas encoder un fichier déjà encodé
		if [ -e "${FLAC_2_ENCODE_DIR}" ]; then 
			echo "NO ENCODE : [${FLAC_2_ENCODE_DIR}]" >> $LOG
			#return 1			
		else
			# [ 1 get tag ] #####################	
			Fonction_get_tag "${i}"
			#####################################

			# [ 2 encode ] ######################
				ffmpeg -v 0 -threads 4 -i "${i}" -acodec alac "${FLAC_2_ENCODE_DIR}" >/dev/null 2>/dev/null	
				# Test de l'encodage en AAC
				#ffmpeg -v 0 -threads 3 -i "${i}" -strict experimental -acodec aac -cutoff 15000 -b 128k "${FLAC_2_ENCODE_DIR}"
				#ffmpeg -v 0 -threads 4 -i "${i}" -strict experimental -acodec aac -cutoff 15000 -b 192k -ac 2 "${FLAC_2_ENCODE_DIR}" >/dev/null 2>/dev/null
			#####################################

			# [ 3 set tag ] #####################	
			Fonction_set_tag "${FLAC_2_ENCODE_DIR}"
			#####################################
					
			# [ 4 gestion erreur] ###############	
			if [ "$?" -eq "0" ];then
				echo "ENCODE : [${i}] --> [${FLAC_2_ENCODE_DIR}]" >> $LOG
			else
				echo "ERREUR ENCODE : [${i}] --> [${FLAC_2_ENCODE_DIR}]" >> $LOG
			fi
			#####################################
			#return 0
		fi
		# J'ai utilisé la fonction suivante une fois pour RE-TAGGER toutes ma musique.
		# Fonction_retag
	done
}

Fonction_retag()
{
	if [ $RETAG -eq "1" ];then
		echo "RETAG : [${FLAC_2_ENCODE_DIR}]" >> $LOG
		Fonction_tag "${i}"
		# Supprime les anciens TAG
		/usr/bin/AtomicParsley "${FLAC_2_ENCODE_DIR}" --artwork REMOVE_ALL

		# Ajoute les nouveaux TAG
		/usr/bin/AtomicParsley "${FLAC_2_ENCODE_DIR}" --overWrite \
					   --artist "${ARTIST}" \
					   --title "${TITLE}" \
					   --album "${ALBUM}" \
					   --genre "${GENRE}" \
					   --tracknum "${TRACKNUMBER}" \
					   --disk "${DISCNUMBER}" \
					   --albumArtist "${ALBUMARTIST}" \
					   --compilation "${COMPILATION}"
		fi
}

Fonction_fin()
{
	IFS=${SAVEIFS}
	echo ""
	echo ""
	echo ""
	echo "         Fin du Traitement [ ffmpeg ] pour FLAC_2_ENCODE : OK"
	echo ""
	echo ""
	echo ""
}

Fonction_init()
{
	#################
	Fonction_test_env
	Fonction_debut
	Fonction_spider_rep
	Fonction_fin
	#################
}


Fonction_init

