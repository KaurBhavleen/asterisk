FROM ubuntu:18.04
RUN apt-get update && \
apt-get -y upgrade
#reboot && \
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Moscow
RUN apt-get install -y tzdata && \
apt-get -y install  subversion git curl wget libnewt-dev libssl-dev libncurses5-dev libsqlite3-dev build-essential libjansson-dev libxml2-dev  uuid-dev && \
apt policy asterisk
RUN cd /usr/src/ && \
curl -O http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-16-current.tar.gz && \
tar xvf asterisk-16-current.tar.gz && \
cd asterisk-16*/ && \
contrib/scripts/get_mp3_source.sh && \
contrib/scripts/install_prereq install && \
./configure
#RUN make -j$(nproc) menuselect.makeopts
#menuselect/menuselect --enable res_snmp menuselect.makeopts && \
RUN cd /usr/src/asterisk-16*/ && make -j$(nproc) menuselect.makeopts \
    && menuselect/menuselect \
                  --disable BUILD_NATIVE \
                  --enable cdr_csv \
                  --enable res_snmp \
                  --enable res_http_websocket \
                  --enable res_hep_pjsip \
                  --enable res_hep_rtcp \
                  --enable res_sorcery_astdb \
                  --enable res_sorcery_config \
                  --enable res_sorcery_memory \
                  --enable res_sorcery_memory_cache \
                  --enable res_pjproject \
                  --enable res_rtp_asterisk \
                  --enable res_ari \
                  --enable res_ari_applications \
                  --enable res_ari_asterisk \
                  --enable res_ari_bridges \
                  --enable res_ari_channels \
                  --enable res_ari_device_states \
                  --enable res_ari_endpoints \
                  --enable res_ari_events \
                  --enable res_ari_mailboxes \
                  --enable res_ari_model \
                  --enable res_ari_playbacks \
                  --enable res_ari_recordings \
                  --enable res_ari_sounds \
                  --enable res_pjsip \
                  --enable res_pjsip_acl \
                  --enable res_pjsip_authenticator_digest \
                  --enable res_pjsip_caller_id \
                  --enable res_pjsip_config_wizard \
                  --enable res_pjsip_dialog_info_body_generator \
                  --enable res_pjsip_diversion \
                  --enable res_pjsip_dlg_options \
                  --enable res_pjsip_dtmf_info \
                  --enable res_pjsip_empty_info \
                  --enable res_pjsip_endpoint_identifier_anonymous \
                  --enable res_pjsip_endpoint_identifier_ip \
                  --enable res_pjsip_endpoint_identifier_user \
                  --enable res_pjsip_exten_state \
                  --enable res_pjsip_header_funcs \
                  --enable res_pjsip_logger \
                  --enable res_pjsip_messaging \
                  --enable res_pjsip_mwi \
                  --enable res_pjsip_mwi_body_generator \
                  --enable res_pjsip_nat \
                  --enable res_pjsip_notify \
                  --enable res_pjsip_one_touch_record_info \
                  --enable res_pjsip_outbound_authenticator_digest \
                  --enable res_pjsip_outbound_publish \
                  --enable res_pjsip_outbound_registration \
                  --enable res_pjsip_path \
                  --enable res_pjsip_pidf_body_generator \
                  --enable res_pjsip_publish_asterisk \
                  --enable res_pjsip_pubsub \
                  --enable res_pjsip_refer \
                  --enable res_pjsip_registrar \
                  --enable res_pjsip_rfc3326 \
                  --enable res_pjsip_sdp_rtp \
                  --enable res_pjsip_send_to_voicemail \
                  --enable res_pjsip_session \
                  --enable res_pjsip_sips_contact \
                  --enable res_pjsip_t38 \
                  --enable res_pjsip_transport_websocket \
                  --enable res_pjsip_xpidf_body_generator \
                  --enable res_stasis \
                  --enable res_stasis_answer \
                  --enable res_stasis_device_state \
                  --enable res_stasis_mailbox \
                  --enable res_stasis_playback \
                  --enable res_stasis_recording \
                  --enable res_stasis_snoop \
                  --enable res_stasis_test \
                  --enable res_statsd \
                  --enable res_timing_timerfd \
menuselect.makeopts && \
make && \
make install && \
make samples && \
make basic-pbx && \
make config && \
ldconfig
RUN groupadd asterisk && \
useradd -r -d /var/lib/asterisk -g asterisk asterisk && \
usermod -aG audio,dialout asterisk && \
chown -R asterisk:asterisk /etc/asterisk \
                          /var/lib/asterisk \
                          /var/log/asterisk \
                          /var/spool/asterisk \
                         /usr/lib/asterisk && \
echo 'AST_USER="asterisk"' >>/etc/default/asterisk && \
echo 'AST_GROUP="asterisk"'  >>/etc/default/asterisk && \
echo 'runuser = asterisk ; The user to run as' >>/etc/asterisk/asterisk.conf && \
echo 'rungroup = asterisk ; The group to run as' >>/etc/asterisk/asterisk.conf
RUN  /etc/init.d/asterisk restart && \
/etc/init.d/asterisk status
RUN apt-get install ufw -y && \
ufw allow 5060/udp
EXPOSE 10000-12000
EXPOSE 8088
EXPOSE 80
USER asterisk
CMD /usr/sbin/asterisk -f
COPY sip.conf /etc/asterisk/sip.conf
COPY rtp.conf /etc/asterisk/rtp.conf
COPY extensions.conf /etc/asterisk/extensions.conf
COPY voicemail.conf /etc/asterisk/voicemail.conf
COPY ari.conf /etc/asterisk/ari.conf
