% 30-Jul-2013 15:27:10 Bajo umbral_solapa, para que sea m�s f�cil rellenar
% las referencias
% 18-Feb-2013 09:53:48 Quito lo de anular todos los trozos que "toquen" un
% frame con m�s de n_peces manchas, porque a veces es demasiado
% restrictivo.
% 24-Jul-2012 11:03:20 Cambio el criterio de intervalos buenos, para que
% use los trozos y pueda aprovechar segmentos m�s largos.
% 01-Dec-2011 12:20:29 Doy la opci�n de que no coja los del borde
% 14-Nov-2011 10:12:57 Corrijo para que no coja el mapa del primer frame
% del intervalo si la segmentaci�n no es buena.
% 09-Nov-2011 18:02:50 A�ado la comprobaci�n de que la segmentaci�n sea
% buena para aceptar el frame para referencias
% 14-Oct-2011 10:33:32 Quito el input n_peces. Lo coger� de datosegm
% 10-Oct-2011 18:56:27 Cambio 'segm' por datosegm.raizarchivo
% 11-Aug-2011 15:09:33 Revierto el cambio anterior, porque hace que un
% frame con mal solapamiento sea ignorado.
% 09-Aug-2011 17:19:42 Corrijo para que no descarte el �ltimo frame del
% intervalo. Para ello, hago que cuando un frame es v�lido lo sea tambi�n
% el siguiente
% 04-Aug-2011 11:47:04 Limpieza general
% 02-Aug-2011 16:59:55 Quito segm_sig. Revierto lo del solapamiento, que
% tampoco era para tanto
% 02-Aug-2011 15:23:15 Cambio el criterio de frames v�lidos de solapamiento
% a distancia. Mola menos, pero corre m�s
% APE 2 ago 11 Viene de segm2intervalosbuenos

% (C) 2014 Alfonso P�rez Escudero, Gonzalo G. de Polavieja, Consejo Superior de Investigaciones Cient�ficas

function intervalosbuenos=datosegm2intervalosbuenos(datosegm,trozos,solapos,indiv,segmbuena,borde,primerframe,quitaborde)

if nargin<2 || isempty(primerframe)
    primerframe=3000; % Para saltar la parte en la que est�n separados
end

if nargin<3 || isempty(quitaborde)
    quitaborde=false; % Por defecto, usa todos
end

n_peces=datosegm.n_peces;
umbral_avance=3; % Est� en pixels
umbral_dist=10; % En pixels
umbral_solapa=.1; % Solapamiento m�nimo permitido para meter el nuevo frame en la referencia

n_frames=size(datosegm.frame2archivo,1);
intervalosbuenos.frames=false(1,n_frames);
archivo_act=0;

% C�lculo de convivencias

% Quito los trozos que aparezcan en la zona previa a primerframe
trozomax=max(max(trozos(1:primerframe-1,:)));
for c_trozos=1:trozomax
    trozos(trozos==c_trozos)=0;
end % c_trozos
n_distintos=sum(trozos>0,2);
n_distintos=sum(trozos>0,2);
framestodos=find(n_distintos==n_peces);
grupostrozos=NaN(length(framestodos),n_peces);
c_grupos=0;
for c_frames=framestodos(:)'
     trozos_act=sort(trozos(c_frames,1:n_peces));
     if c_grupos==0 || any(grupostrozos(c_grupos,:)~=trozos_act)
         c_grupos=c_grupos+1;
         grupostrozos(c_grupos,:)=trozos_act;
     end % if es un grupo nuevo
end % c_frames
grupostrozos=grupostrozos(1:c_grupos,:);

trozosbuenos=sort(unique(grupostrozos(:)));
trozo2nfbuenos=NaN(1,max(trozos(:)));
manchasbuenas=false(size(trozos));
% Busca frames v�lidos y no demasiado solapantes en cada trozo
for c_trozos=trozosbuenos(:)'
    ind=find(trozos==c_trozos);
    [frame,mancha]=ind2sub(size(trozos),ind);
    [s,orden]=sort(frame);
    solapos_act=solapos(ind(orden));
    if quitaborde
        buenos_act=indiv(ind(orden)) & segmbuena(ind(orden)) & ~borde(ind(orden));
    else
        buenos_act=indiv(ind(orden)) & segmbuena(ind(orden));
    end
    pos_act=-Inf;
    siguiente=find(solapos_act>=pos_act+umbral_solapa,1);   
    n_img=length(ind);
    while ~isempty(siguiente) && siguiente<=n_img
        siguiente_old=siguiente;
        while siguiente<=n_img && ~buenos_act(siguiente)
            siguiente=siguiente+1;
        end
        if siguiente<=n_img
            manchasbuenas(ind(orden(siguiente)))=true;
            pos_act=solapos_act(siguiente);
            siguiente=find(solapos_act>=pos_act+umbral_solapa,1);
        end
    end
    trozo2nfbuenos(c_trozos)=sum(manchasbuenas(ind));
end

intervalosbuenos.grupostrozos=grupostrozos;
intervalosbuenos.manchasbuenas=manchasbuenas;
intervalosbuenos.trozo2nfbuenos=trozo2nfbuenos;
